# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL


class Operate(object):
    """ most of these are notification
    """
    def OnBufferEnter(self, engine_obj, version):
        results_ = engine_obj.OnBufferEnter(version)
        source_info = engine_obj.GetInfo()
        engine_name = source_info['Name']
        if results_ is not None:
            results_['Event'] = version['Event']
            results_['ID'] = version['VersionID']
            results_['EngineName'] = engine_name
        return results_

    def OnBufferTextChanged(self, engine_obj, version):
        results_ = engine_obj.OnBufferTextChanged(version)
        source_info = engine_obj.GetInfo()
        engine_name = source_info['Name']
        if results_ is not None:
            results_['Event'] = version['Event']
            results_['ID'] = version['VersionID']
            results_['EngineName'] = engine_name
        return results_

    def OnInsertModeLeave(self, engine_obj, version):
        results_ = engine_obj.OnInsertModeLeave(version)
        source_info = engine_obj.GetInfo()
        engine_name = source_info['Name']
        if results_ is not None:
            results_['Event'] = version['Event']
            results_['ID'] = version['VersionID']
            results_['EngineName'] = engine_name
        return results_
