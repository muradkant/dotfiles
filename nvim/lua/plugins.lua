local install_path = vim.fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
local packer_bootstrap = false

if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
  vim.fn.system({
    'git',
    'clone',
    '--depth',
    '1',
    'https://github.com/wbthomason/packer.nvim',
    install_path,
  })
  packer_bootstrap = vim.v.shell_error == 0
end

return require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'
  use 'morhetz/gruvbox'
  use 'MeanderingProgrammer/render-markdown.nvim'

  if packer_bootstrap then
    require('packer').sync()
  end
end)
