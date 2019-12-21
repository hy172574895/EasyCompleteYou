──────────────────────────────────────────────────
─██████████████─██████████████─████████──████████─
─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░██──██░░░░██─
─██░░██████████─██░░██████████─████░░██──██░░████─
─██░░██─────────██░░██───────────██░░░░██░░░░██───
─██░░██████████─██░░██───────────████░░░░░░████───
─██░░░░░░░░░░██─██░░██─────────────████░░████─────
─██░░██████████─██░░██───────────────██░░██───────
─██░░██─────────██░░██───────────────██░░██───────
─██░░██████████─██░░██████████───────██░░██───────
─██░░░░░░░░░░██─██░░░░░░░░░░██───────██░░██───────
─██████████████─██████████████───────██████───────
──────────────────────────────────────────────────
              EASILY COMPLETE YOU.
# Brief Introduction
1. Collaborate with ycm, can be a extend for YCM.
2. Fluently completion.
3. Write in Python3.
4. Fuzzy-find support like YCM.
5. Buildin LSP.
6. Out of the box.

# How to install

### Requires

1. Python >= 3.0
strongly suggest to use python3 (> 3.6)
2. Vim >= 8.0
strongly suggest to use the newest one(Vim 8.2).

### Install

#### Options 1:
Using some Plugin-manager like Plug-vim or Vunble:
Put the line into your vimrc, then install it.
`hy172574895/EasyCompleteYou`

#### Options 2:

download the whole repository and put it into vim's starting dir

### Usage

After the install ECY successfully, there are two buildin completion source that
is `Label` and `Snippets`.
Firstly ECY will detect the filetype of your buffer that you using. Knowing the 
filetype, then ECY asks the server what sources are available on this filetype.
So if you want a specific source work on a buffer, you can change the filetype 
by the vim that `set &filetype=java` on the buffer you want to change.

#### Enable more.

there only two sources in ECY after you installed ECY. If you want ECY work
on `python`, you can activate a source by:
`:call ECY_Installer('Python')` in vim

Here the full list of sources that ECY supports. 
