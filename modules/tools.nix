# Helper scripts as executable store outputs (replaces bin/* link loop).
{
  home.file = {
    ".local/bin/swash-screenshot" = { source = ../files/bin/swash-screenshot; executable = true; };
    ".local/bin/wait-for-tcp" = { source = ../files/bin/wait-for-tcp; executable = true; };
    "Pictures/background.jpg".source = ../files/background.jpg;
    "Pictures/lockscreen.jpg".source = ../files/lockscreen.jpg;
  };
}
