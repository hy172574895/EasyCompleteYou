# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

import logging

fileHandler = logging.FileHandler("D:/gvim/vimfiles/myplug/ECY_new/python/server/server_log/ECY_server.log", mode="w", encoding="UTF-8")
fileHandler.setLevel(logging.DEBUG)
formatter = logging.Formatter('%(asctime)s  %(filename)s : %(levelname)s  %(message)s')
fileHandler.setFormatter(formatter)
logging.getLogger('ECY').addHandler(fileHandler)
logging.getLogger('ECY').error("sdf")
     
