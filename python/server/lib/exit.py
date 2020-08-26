# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

class Operate(object):

    def Exit(self, all_engine_obj,  version):
        for name, values in all_engine_obj.items():
            if 'Object' in values:
                values['Object'].Exit(version)
