# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

import sys
# {{{ 
class _fake_logger():

    def add(self):
        pass

    def debug(self):
        pass

    def remove(self):
        pass

    def bind(self):
        pass

    def contextualize(self):
        pass

    def log(self):
        pass

    def level(self):
        pass

    def enable(self):
        pass

    def disable(self):
        pass
# }}}

class ECY_logger():
    def __init__(self, is_logging, log_output_dir):
        try:
            from loguru import logger as loguru_log
        except Exception as e:
            self.SayGoodBye("Please 'pip install loguru' (requires Python >= 3.5) for debugging.")
        self._logger = loguru_log
        # remove the default one of stdout of handler
        self._logger.remove()
        if is_logging:
            if log_output_dir is None:
                self.SayGoodBye("missing output dir of log files.")
            self._logger.add(log_output_dir + "/ECY_server.log",
                             format="{file} {line} {function} {level} => {message}\n{exception}",
                             rotation="50 MB", level="DEBUG")

    def GetLogger(self):
        return self._logger

    def SayGoodBye(self, left_msg):
        print(left_msg + "\n")
        exit()

    # def __init__(self, level=logging.CRITICAL):
    #     self._level = level
    #     self.logger = logging.getLogger('ecy')
    #     self.logger.setLevel(self._level)

    # def set_level(self, level=logging.DEBUG):
    #     self._level = level
    #     self.logger.setLevel(self._level)

    # def Add_handler(self, dir_):
    #     rq = time.strftime('%Y%m%d%H%M', time.localtime(time.time()))
    #     log_path = dir_
    #     log_name = log_path + rq + '.log'
    #     logfile = log_name
    #     fh = logging.FileHandler(logfile, mode='w', encoding='utf-8')
    #     fh.setLevel(logging.DEBUG)
    #     formatter = logging.Formatter(
    #         "%(asctime)s - %(filename)s[line:%(lineno)d] - \
    #             %(levelname)s: %(message)s")
    #     fh.setFormatter(formatter)
    #     self.logger.addHandler(fh)

# test.Add_handler('D:/gvim/vimfiles/myplug/python_version/python/server_lib/user_cache/log/')
