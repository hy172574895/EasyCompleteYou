# Author: Jimmy Huang (1902161621@qq.com)
# some codes copied from YCM

import os
import os.path as p
import sys
import zipfile
import json

import argparse
parser = argparse.ArgumentParser(description='EasyCompleteYou installer, Easily install.')
parser.add_argument('--clangd', action='store_true', help='language server of clangd. Linux, Windows and Mac. x86')
parser.add_argument('--rust_analyzer', action='store_true', help='language server of rust_analyzer. Linux, Windows and Mac. x86')
parser.add_argument('--nodejs', action='store_true', help='nodejs, programming language. Linux and Mac in x64. Windows in x86')
parser.add_argument('--html_lsp',action='store_true', help='language server of html, and html-hint, Depends on nodejs. Linux and Mac in x64. Windows in x86.')
g_args = parser.parse_args()

global DIR_OF_THIRD_PARTY
DIR_OF_THIRD_PARTY = p.dirname( p.abspath( __file__ ) )
sys.path[ 0:0 ] = [ p.join( DIR_OF_THIRD_PARTY, 'installer_deps', 'requests' ),
                    p.join( DIR_OF_THIRD_PARTY,
                            'installer_deps',
                            'urllib3',
                            'src' ),
                    p.join( DIR_OF_THIRD_PARTY, 'installer_deps', 'chardet' ),
                    p.join( DIR_OF_THIRD_PARTY, 'installer_deps', 'certifi' ),
                    p.join( DIR_OF_THIRD_PARTY, 'installer_deps', 'idna' ) ]
import requests

class Installer(object):
    """ all the dir should end with no '/'
    """
    def __init__(self, dependences, engine_name,
            install_dir=None, region='world', download_cache_dir=None):

        self.download_cache_dir = download_cache_dir
        self.install_dir = install_dir

        self.dependences = dependences
        self._region = region
        self.install_name = engine_name

    def _init_dir(self, dirs):
        if not os.path.isdir(dirs):
            os.mkdir(dirs)
        return dirs

    def _init_install_dir(self):
        temp = self.install_dir
        global DIR_OF_THIRD_PARTY
        if temp is None:
            path = DIR_OF_THIRD_PARTY + '/engines_deps'
            path = self._init_dir(path)
            path = DIR_OF_THIRD_PARTY + '/engines_deps/' + self.install_name
        else:
            path = temp
        path = self._init_dir(path)
        path += '/'
        print('dependences installation dir: %s' % path)
        self.install_dir = path
        return path

    def _init_download_cache_dir(self):
        temp = self.download_cache_dir
        global DIR_OF_THIRD_PARTY
        if temp is None:
            path = DIR_OF_THIRD_PARTY + '/download_cache'
            path = self._init_dir(path)
            path = DIR_OF_THIRD_PARTY + '/download_cache/' + self.install_name
        else:
            path = temp
        path = self._init_dir(path)
        path += '/'
        print('download cache dir: %s' % path)
        self.download_cache_dir = path
        return path

    def _download_to(self, download_url,file_path):
        request = requests.get( download_url, stream = True )
        with open( file_path, 'wb' ) as package_file:
            package_file.write( request.content )
        request.close()

    def Install(self):
        print('-------------------------------')
        print('Installing ' + self.install_name)
        print('-------------------------------')
        self._init_download_cache_dir()
        self._init_install_dir()
        if not self.CheckInstall():
            self.DownloadDependences()
            self.DecompressZIPToInstallDir()
            self.OrginizeDependences()
        return self.DoneInstallation()

    def DownloadDependences(self):
        print('')
        print('Downloading %s ZIP dependences.' % len(self.dependences))
        for item in self.dependences:
            url = self.ChooseBestUrl(item)
            dep_name = self.download_cache_dir + item['name']
            self._download_to(url, dep_name)
            print('"%s" downloaded to: %s' % (item['name'], dep_name))
        print('')

    def ChooseBestUrl(self, item):
        """ choose the best url to download
        """
        os_type = self.GetCurrentOS()
        if self._region not in item['url']:
            self._region = 'world'
        all_url = item['url'][self._region]
        url = all_url[os_type]

        print('')
        print('Current OS: %s' % os_type)
        print('Using mirror in %s wild' % self._region)
        print('Downloading "%s" from: %s' % (item['name'], url))
        return url

    def OrginizeDependences(self):
        value = {}
        dirs = self.install_dir + self.install_name
        for item in self.dependences:
            value[item['name']] = dirs + '/' + item['name'] + '/'
        WriteConif(self.install_name, value)

    def CheckInstall(self):
        """ check if it was installed.
        """
        return False
        
    def DoneInstallation(self):
        print('Installed')

    def DownloadFileTo( download_url, file_path ):
        request = requests.get( download_url, stream = True )
        with open( file_path, 'wb' ) as package_file:
            package_file.write( request.content )
        request.close()

    def GetCurrentOS(self):
        temp = sys.platform
        if temp == 'win32':
            return 'windows'
        if temp == 'darwin':
            return 'mac'
        return 'linux'

    def GetRegion(self):
        return 'world'

    def DecompressZIPToInstallDir(self):
        print('-------------------------------')
        print('Decompressing')
        print('-------------------------------')
        for item in self.dependences:
            zip_cache = self.download_cache_dir + item['name']
            print('Decompressing %s' % zip_cache)
            dirs = self.install_dir + self.install_name
            dirs = self._init_dir(dirs)
            if not zipfile.is_zipfile(zip_cache):
                raise "Fatal error. Unpackable ZIP " + zip_cache
            zip_file = zipfile.ZipFile(zip_cache)
            name = dirs + "/" + item['name']
            for names in zip_file.namelist():
                zip_file.extract(names, name)
            zip_file.close()
            print('Decompressed to: %s' % name)
        print('')

def GetRegion():
    # for now
    return 'world'
    try:
        print('-------------------------------')
        print('Getting your IP.')
        r=requests.get(url='http://ip-api.com/json/')
        temp = r.json() 
        print(temp)
        if temp['country'] == 'China':
            return 'China'
        return 'world'
    except:
        print('Failed to get your IP.')
        return 'world'
    finally:
        print('')
region = GetRegion()

def InitConfig():
    config_path = DIR_OF_THIRD_PARTY + '/installed_engines.json'
    if not os.path.exists(config_path):
        init_content = {'is_init': 'true'}
        with open(config_path, 'w+', encoding='utf-8') as f:
            f.write(json.dumps(init_content))
        return init_content

    # read config
    with open(config_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    return json.loads(content)

def WriteConif(key, value):
    config_path = DIR_OF_THIRD_PARTY + '/installed_engines.json'
    if type(config_content) is not dict:
        raise
    config_content[key] = value
    config_content['is_init'] = 'false'
    with open(config_path, 'w+', encoding='utf-8') as f:
        f.write(json.dumps(config_content))

global config_content
config_content = InitConfig()

#######################################################################
#                               clangd                                #
#######################################################################
world_url = {}
world_url['windows'] = 'https://github.com/clangd/clangd/releases/download/snapshot_20200503/clangd-windows-snapshot_20200503.zip'
world_url['linux']   = 'https://github.com/clangd/clangd/releases/download/snapshot_20200503/clangd-linux-snapshot_20200503.zip'
world_url['mac']     = 'https://github.com/clangd/clangd/releases/download/snapshot_20200503/clangd-mac-snapshot_20200503.zip'

# china_url = {}
# china_url['linux']   = 'https://gitee.com/Jimmy_Huang/for_ECY_download/attach_files/387671/download'
# china_url['mac']     = 'https://gitee.com/Jimmy_Huang/for_ECY_download/attach_files/387672/download'
# china_url['windows'] = 'https://gitee.com/Jimmy_Huang/for_ECY_download/attach_files/387673/download'

all_url = {'world':world_url}

dependences = []
dependences.append({'url':all_url, 'name':'clangd'})
clangd = Installer(dependences,'clangd', region=region)


#######################################################################
#                                gopls                                #
#######################################################################

#######################################################################
#                               nodejs                                #
#######################################################################
world_url = {}
# offical nodejs link for linux and max are not ZIP. so I put it to github
world_url['windows'] = 'https://nodejs.org/dist/v12.16.3/node-v12.16.3-win-x86.zip'
world_url['linux']   = 'https://github.com/hy172574895/for_ECY_download/releases/download/nodejs-01/node-v12.16.3-linux-x64.zip'
world_url['mac']     = 'https://github.com/hy172574895/for_ECY_download/releases/download/nodejs-01/node-v12.16.3-darwin-x64.zip'

# china_url = {}
# china_url['windows'] = 'https://nodejs.org/dist/v12.16.3/node-v12.16.3-win-x86.zip'
# china_url['linux']   = 'https://gitee.com/Jimmy_Huang/for_ECY_download/attach_files/388535/download'
# china_url['mac']     = 'https://gitee.com/Jimmy_Huang/for_ECY_download/attach_files/388536/download'

all_url = {'world':world_url}

dependences = []
dependences.append({'url':all_url, 'name':'nodejs'})
nodejs = Installer(dependences,'nodejs', region=region)


#######################################################################
#                       html_lsp and html_hint                        #
#######################################################################
world_url = {}
# offical nodejs link for linux and max are not ZIP. so I put it to github
world_url['windows'] = 'https://nodejs.org/dist/v12.16.3/node-v12.16.3-win-x86.zip'
world_url['linux']   = 'https://github.com/hy172574895/for_ECY_download/releases/download/nodejs-01/node-v12.16.3-linux-x64.zip'
world_url['mac']     = 'https://github.com/hy172574895/for_ECY_download/releases/download/nodejs-01/node-v12.16.3-darwin-x64.zip'

# china_url = {}
# china_url['windows'] = 'https://nodejs.org/dist/v12.16.3/node-v12.16.3-win-x86.zip'
# china_url['linux']   = 'https://gitee.com/Jimmy_Huang/for_ECY_download/attach_files/388535/download'
# china_url['mac']     = 'https://gitee.com/Jimmy_Huang/for_ECY_download/attach_files/388536/download'

all_url = {'world':world_url}

dependences = []
dependences.append({'url':all_url, 'name':'nodejs'})
html_lsp = Installer(dependences,'nodejs', region=region)

###############
#  html_hint  #
###############
world_url = {}
# offical nodejs link for linux and max are not ZIP. so I put it to github
world_url['windows'] = 'https://nodejs.org/dist/v12.16.3/node-v12.16.3-win-x86.zip'
world_url['linux']   = 'https://github.com/hy172574895/for_ECY_download/releases/download/nodejs-01/node-v12.16.3-linux-x64.zip'
world_url['mac']     = 'https://github.com/hy172574895/for_ECY_download/releases/download/nodejs-01/node-v12.16.3-darwin-x64.zip'

# china_url = {}
# china_url['windows'] = 'https://nodejs.org/dist/v12.16.3/node-v12.16.3-win-x86.zip'
# china_url['linux']   = 'https://gitee.com/Jimmy_Huang/for_ECY_download/attach_files/388535/download'
# china_url['mac']     = 'https://gitee.com/Jimmy_Huang/for_ECY_download/attach_files/388536/download'

all_url = {'world':world_url}

dependences = []
dependences.append({'url':all_url, 'name':'nodejs'})
html_hint = Installer(dependences,'nodejs', region=region)


#######################################################################
#                               testing                               #
#######################################################################
if g_args.clangd:
    clangd.Install()

if g_args.nodejs:
    nodejs.Install()

if g_args.html_lsp:
    nodejs.Install()
    html_lsp.Install()
    html_hint.Install()


