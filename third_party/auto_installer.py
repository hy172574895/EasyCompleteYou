# Author: Jimmy Huang (1902161621@qq.com)
# some codes copied from YCM

import os
import os.path as p
import sys
import zipfile
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
    """
    """
    def __init__(self, dependences, engine_name,
            install_dir=None, region='world', download_cache_dir=None):

        #####################################
        #  all the dir should end with no '/'  #
        #####################################
        self.download_cache_dir = download_cache_dir
        self.install_dir = install_dir

        self.dependences = dependences
        self._region = region
        self.install_name = engine_name

    def _init_install_dir(self):
        temp = self.install_dir
        global DIR_OF_THIRD_PARTY
        if temp is None:
            path = DIR_OF_THIRD_PARTY + '/engines_deps'
            if not os.path.isdir(path):
                os.mkdir(path)
            path = DIR_OF_THIRD_PARTY + '/engines_deps/' + self.install_name
        else:
            path = temp
        if not os.path.isdir(path):
            os.mkdir(path)
        path += '/'
        print('dependences installation dir: %s' % path)
        self.install_dir = path
        return path

    def _init_download_cache_dir(self):
        temp = self.download_cache_dir
        global DIR_OF_THIRD_PARTY
        if temp is None:
            path = DIR_OF_THIRD_PARTY + '/download_cache'
            if not os.path.isdir(path):
                os.mkdir(path)
            path = DIR_OF_THIRD_PARTY + '/download_cache/' + self.install_name
        else:
            path = temp
        if not os.path.isdir(path):
            os.mkdir(path)
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
            print('Downloading "%s" from: %s' % (item['name'], url))
            dep_name = self.download_cache_dir + item['name']
            self._download_to(url, dep_name)
            print('"%s" downloaded to: %s' % (item['name'], dep_name))
        print('')

    def ChooseBestUrl(self, item):
        """ choose the best url to download
        """
        os_type = self.GetCurrentOS()
        all_url = item['url'][self._region]
        return all_url[os_type]

    def OrginizeDependences(self):
        pass

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
            dirs = self.install_dir + item['name']
            if not os.path.isdir(dirs):
                os.mkdir(dirs)
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

#######################################################################
#                               clangd                                #
#######################################################################
world_url = {}
world_url['windows'] = 'https://github.com/clangd/clangd/releases/download/snapshot_20200503/clangd-windows-snapshot_20200503.zip'
world_url['linux']   = 'https://github.com/clangd/clangd/releases/download/snapshot_20200503/clangd-linux-snapshot_20200503.zip'
world_url['mac']     = 'https://github.com/clangd/clangd/releases/download/snapshot_20200503/clangd-mac-snapshot_20200503.zip'

china_url = {}
china_url['windows'] = 'https://github.com/clangd/clangd/releases/download/snapshot_20200503/clangd-windows-snapshot_20200503.zip'
china_url['linux']   = 'https://github.com/clangd/clangd/releases/download/snapshot_20200503/clangd-linux-snapshot_20200503.zip'
china_url['mac']     = 'https://github.com/clangd/clangd/releases/download/snapshot_20200503/clangd-mac-snapshot_20200503.zip'

all_url = {'China': china_url, 'world':world_url}

dependences = []
dependences.append({'url':all_url, 'name':'clangd'})
clangd = Installer(dependences,'clangd', region=region)


#######################################################################
#                                gopls                                #
#######################################################################


#######################################################################
#                               testing                               #
#######################################################################
clangd.Install()
