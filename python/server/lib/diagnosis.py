# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL


class Operate(object):

    def Diagnosis(self, engine_obj,  version):
        results = engine_obj.Diagnosis(version)
        engine_name = engine_obj['Name']
        if results is not None and 'ErroCode' not in results:
            results['Event'] = 'diagnosis'
            results['EngineName'] = engine_name
        return results
