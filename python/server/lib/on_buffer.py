# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL


class Operate(object):
    def OnBufferEnter(self, engine_obj, version):
        results_ = engine_obj.OnBufferEnter(version)
        engine_name = engine_obj['Name']
        if results_ is not None:
            results_['Event'] = version['Event']
            results_['Version_ID'] = version['VersionID']
            results_['EngineName'] = engine_name
        return results_

    def OnBufferTextChanged(self, engine_obj, version):
        results_ = engine_obj.OnBufferTextChanged(version)
        engine_name = engine_obj['Name']
        if results_ is not None:
            results_['Event'] = version['Event']
            results_['Version_ID'] = version['VersionID']
            results_['EngineName'] = engine_name
        return results_
