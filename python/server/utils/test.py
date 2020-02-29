def _filter_log_msg(msg):
    """ return True means filter this msg.
    """
    if msg.find('no dep handle') != -1:
        # can not find that package
        return True
    if msg.find('AST') != -1:
        return True
    return False
print(_filter_log_msg('AdST'))

