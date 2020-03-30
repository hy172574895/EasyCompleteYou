# some of the code was copy from youcompleteme, please obey the license of it.
# standard lib of python
import vim
import os


# local lib

def CallEval(arg1):
    temp = vim.eval(arg1)
    if type(temp) == str:
        if temp == 'True':
            return True
        if temp == 'False':
            return False
    return temp


def Command(arg1):
    return vim.command(arg1)


def CurrentLineContents():
    return ToUnicode(vim.current.line)


def CurrentLineAndColumn():
    """Returns the 0-based current line and 0-based current column."""
    # See the comment in CurrentColumn about the calculation for the line and
    # column number
    line, column = vim.current.window.cursor
    line -= 1
    return line, column


def BufferModified(buffer_object):
    return buffer_object.options['mod']


def CurrenLineNr():
    line, temp = vim.current.window.cursor
    return line-1


def CurrentColumn():
    """Returns the 0-based current column. Do NOT access the CurrentColumn in
    vim.current.line. It doesn't exist yet when the cursor is at the end of the
    line. Only the chars before the current column exist in vim.current.line.
    """

    # vim's columns are 1-based while vim.current.line columns are 0-based
    # ... but vim.current.window.cursor (which returns a (line, column) tuple)
    # columns are 0-based, while the line from that same tuple is 1-based.
    # vim.buffers buffer objects OTOH have 0-based lines and columns.
    # Pigs have wings and I'm a loopy purple duck. Everything makes sense now.
    return vim.current.window.cursor[1]


def GetBufferFilepath(buffer_object):
    if buffer_object.name:
        return os.path.normpath(ToUnicode(buffer_object.name))
    # Buffers that have just been created by a command like :enew don't have
    # any buffer name so we use the buffer number for that.
    return os.path.join(ToUnicode(os.getcwd()), str(buffer_object.number))


def JoinLinesAsUnicode(lines):
    try:
        first = next(iter(lines))
    except StopIteration:
        return str()
    if isinstance(first, str):
        return ToUnicode('\n'.join(lines))
    if isinstance(first, bytes):
        return ToUnicode(b'\n'.join(lines))
    raise ValueError('lines must contain either strings or bytes.')


def GetBufferAllText(buffer_nr):
    buf_object = GetBufferObject(buffer_nr)
    return JoinLinesAsUnicode(buf_object) + '\n'


def GetBufferTypes(buffer_nr):
    command = 'getbufvar({0}, "&ft")'.format(buffer_nr)
    return ToUnicode(CallEval(command)).split('.')


def GetBufferVar(bufnr, var):
    command = 'getbufvar('+str(bufnr) + ',"'+var+'")'
    return ToUnicode(CallEval(command)).split('.')


def GetCurrentBufferNumber():
    return vim.current.buffer.number


def GetCurrentBufferFilePath():
    try:
        return CallEval('utility#GetCurrentBufferPath()')
    except:
        # have bug in popup windows
        return GetBufferFilepath(GetCurrentBufferObject())


def GetCurrentBufferObject():
    return GetBufferObject(GetCurrentBufferNumber())


def GetBufferObject(buffer_nr):
    return vim.buffers[buffer_nr]


def GetCurrentBufferType():
    current_buffer_type = GetBufferTypes(GetCurrentBufferNumber())
    return current_buffer_type[0]


def CurrenBufferText():
    return GetBufferAllText(GetCurrentBufferNumber())


def CurrentBufferText_with_wrap():
    return JoinLinesAsUnicode(GetCurrentBufferNumber())


def ToUnicode(value):
    if not value:
        return str()
    if isinstance(value, str):
        return value
    if isinstance(value, bytes):
        # All incoming text should be utf8
        return str(value, 'utf8')
    return str(value)


def GetVariableValue(variable):
    return CallEval(variable)
