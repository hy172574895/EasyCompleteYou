syn match ECY_diagnosis_erro_hi  display '^ECY_diagnosis_erro'
syn match ECY_diagnosis_warn_hi  display '^ECY_diagnosis_warn'
syn match ECY_diagnosis_nr  display '(.*)'
syn match ECY_diagnosis_text  display '^(.*)'
syn match ECY_diagnosis_linenr  display '\[.*\]'

hi def link ECY_diagnosis_erro_hi Error
hi def link ECY_diagnosis_warn_hi TODO
hi def link ECY_diagnosis_text String
hi def link ECY_diagnosis_nr Search
hi def link ECY_diagnosis_linenr CursorLineNr
