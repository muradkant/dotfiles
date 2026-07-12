#!/usr/bin/env python3
"""Small OpenAI-compatible Kokoro TTS service."""

from __future__ import annotations

import io
import json
import logging
import os
import re
import tempfile
import threading
import time
from contextlib import asynccontextmanager
from pathlib import Path
from typing import Literal

import numpy as np
import soundfile as sf
from fastapi import FastAPI, HTTPException
from fastapi.responses import Response
from kokoro import KModel, KPipeline
from pydantic import BaseModel, Field
from starlette.concurrency import run_in_threadpool

logging.basicConfig(level=logging.INFO)
log = logging.getLogger("kokoro-tts")

DICT_PATH = Path.home() / ".config" / "kokoro-tts" / "pronunciation_dict.json"
MODEL_DIR = Path(os.environ["KOKORO_MODEL_DIR"]) if os.getenv("KOKORO_MODEL_DIR") else None
REPO_ID = "hexgrad/Kokoro-82M"
VOICE_RE = re.compile(r"^[a-z]{2}_[a-z0-9_]+$")
SYNTHESIS_LOCK = threading.Lock()

model: KModel | None = None
pipeline: KPipeline | None = None


class SpeechRequest(BaseModel):
    model: str = "kokoro"
    input: str = Field(min_length=1, max_length=10_000)
    voice: str = "af_heart"
    response_format: Literal["wav", "flac", "ogg"] = "wav"
    speed: float = Field(default=1.0, ge=0.25, le=4.0)


class DictEntry(BaseModel):
    word: str = Field(min_length=1, max_length=200)
    phonemes: str = Field(min_length=1, max_length=500)


def load_pronunciations() -> dict[str, str]:
    if not DICT_PATH.exists():
        return {}
    with DICT_PATH.open(encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict) or not all(
        isinstance(key, str) and isinstance(item, str) for key, item in value.items()
    ):
        raise ValueError(f"invalid pronunciation dictionary: {DICT_PATH}")
    return value


def save_pronunciations(value: dict[str, str]) -> None:
    DICT_PATH.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    with tempfile.NamedTemporaryFile(
        "w", encoding="utf-8", dir=DICT_PATH.parent, delete=False
    ) as handle:
        json.dump(value, handle, indent=2, ensure_ascii=False)
        handle.write("\n")
        temporary = Path(handle.name)
    temporary.chmod(0o600)
    os.replace(temporary, DICT_PATH)


def install_pronunciations(value: dict[str, str]) -> None:
    assert pipeline is not None
    for word, phonemes in value.items():
        pipeline.g2p.lexicon.golds[word] = phonemes
        pipeline.g2p.lexicon.golds[word.lower()] = phonemes


def load_model() -> tuple[KModel, KPipeline]:
    if MODEL_DIR:
        loaded_model = KModel(
            repo_id=REPO_ID,
            config=str(MODEL_DIR / "config.json"),
            model=str(MODEL_DIR / "kokoro-v1_0.pth"),
        ).eval()
    else:
        loaded_model = KModel(repo_id=REPO_ID).eval()
    loaded_pipeline = KPipeline(lang_code="a", repo_id=REPO_ID, model=loaded_model)
    return loaded_model, loaded_pipeline


@asynccontextmanager
async def lifespan(_: FastAPI):
    global model, pipeline
    log.info("Loading Kokoro model...")
    model, pipeline = await run_in_threadpool(load_model)
    pronunciations = load_pronunciations()
    install_pronunciations(pronunciations)
    log.info("Model loaded. %d pronunciation overrides active.", len(pronunciations))
    yield
    model = None
    pipeline = None


app = FastAPI(title="Kokoro TTS", lifespan=lifespan)


def resolve_voice(name: str) -> str:
    if not VOICE_RE.fullmatch(name):
        raise ValueError("voice must be a single Kokoro voice name")
    if not MODEL_DIR:
        return name
    voice = MODEL_DIR / "voices" / f"{name}.pt"
    if not voice.is_file():
        raise ValueError(f"voice is absent from pinned model snapshot: {name}")
    return str(voice)


def synthesize(request: SpeechRequest) -> bytes:
    assert pipeline is not None
    voice = resolve_voice(request.voice)
    with SYNTHESIS_LOCK:
        chunks = [
            result.audio.cpu().numpy()
            for result in pipeline(request.input, voice=voice, speed=request.speed)
        ]
    if not chunks:
        raise ValueError("no audio generated")
    audio = np.concatenate(chunks)
    output = io.BytesIO()
    sf.write(output, audio, 24_000, format=request.response_format.upper())
    return output.getvalue()


@app.post("/v1/audio/speech")
async def create_speech(request: SpeechRequest) -> Response:
    started = time.monotonic()
    try:
        audio = await run_in_threadpool(synthesize, request)
    except ValueError as error:
        raise HTTPException(400, str(error)) from error
    elapsed = time.monotonic() - started
    log.info("Generated %d bytes in %.2fs", len(audio), elapsed)
    media = {"wav": "audio/wav", "flac": "audio/flac", "ogg": "audio/ogg"}
    return Response(content=audio, media_type=media[request.response_format])


@app.post("/v1/pronunciation")
async def add_pronunciation(entry: DictEntry) -> dict[str, str]:
    value = load_pronunciations()
    value[entry.word] = entry.phonemes
    value[entry.word.lower()] = entry.phonemes
    save_pronunciations(value)
    install_pronunciations({entry.word: entry.phonemes})
    return {"status": "ok", "word": entry.word, "phonemes": entry.phonemes}


@app.get("/v1/pronunciation")
async def list_pronunciations() -> dict[str, str]:
    return load_pronunciations()


@app.delete("/v1/pronunciation/{word}")
async def delete_pronunciation(word: str) -> dict[str, str]:
    assert pipeline is not None
    value = load_pronunciations()
    matching = [key for key in value if key.casefold() == word.casefold()]
    if not matching:
        raise HTTPException(404, f"No pronunciation override for '{word}'")
    for key in matching:
        value.pop(key)
        pipeline.g2p.lexicon.golds.pop(key, None)
        pipeline.g2p.lexicon.golds.pop(key.lower(), None)
    save_pronunciations(value)
    return {"status": "deleted", "word": word}


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok", "model": "kokoro-82m"}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="127.0.0.1", port=8890)
