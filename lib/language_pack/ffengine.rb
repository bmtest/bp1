require "language_pack/java"
require "fileutils"

# TODO logging
module LanguagePack
  class FFEngine < Java
    include LanguagePack::PackageFetcher

    FFEngine_REL_VERSION = "R1.4.0.1"
    FFEngine_SVN_VERSION = "R2872"
    FFEngine_DOWNLOAD = "https://system.fatfractal.com/repo/artifact/Releases/#{FFEngine_REL_VERSION}"
    FFEngine_PACKAGE =  "FF_RUNTIME_#{FFEngine_REL_VERSION}_#{FFEngine_SVN_VERSION}.zip".freeze
    FFEngine_TOP_DIR = "FatFractal_Runtime"

    def self.use?
      true
    end

    def name
      "FFEngine"
    end

    def compile
      Dir.chdir(build_path) do
        install_java
        install_ffengine
        move_ffengine_to_root
        copy_resources
        # setup_profiled is part of our superclass (Java)
        setup_profiled
      end
    end

    def install_ffengine
      FileUtils.mkdir_p ffengine_dir
      ffengine_tarball="#{ffengine_dir}/#{FFEngine_PACKAGE}"

      download_ffengine ffengine_tarball

      puts "Unpacking FFEngine to #{ffengine_dir}"
      puts run_with_err_output("echo starting jar extract; $(JAVA_HOME)/jar xvf #{ffengine_tarball} -C #{ffengine_dir} ; echo jar extract complete")
      puts "Listing contents of #{ffengine_dir}"
      run_with_err_output("ls -al #{ffengine_dir}")
      puts "Removing #{ffengine_tarball}"
      FileUtils.rm_rf ffengine_tarball
      puts "Checking for #{FFEngine_TOP_DIR}/bin/ff-service"
      unless File.exists?("#{ffengine_dir}/#{FFEngine_TOP_DIR}/bin/ff-service")
        puts "Unable to download FFEngine"
        exit 1
      end
    end

    def download_ffengine(ffengine_tarball)
      # TODO : Keep the tarball around, check for it next time instead of re-downloading
      if (File.exists(ffengine_tarball))
        puts "###"
        puts "# tarball found - shouldn't really download again"
        puts "###"
      end
      # TODO : Do the same for the JDK
      puts "Downloading FFEngine: #{FFEngine_PACKAGE}"
      fetch_package FFEngine_PACKAGE, FFEngine_DOWNLOAD
      puts "Downloaded FFEngine: #{FFEngine_PACKAGE}"
      FileUtils.mv FFEngine_PACKAGE, ffengine_tarball
    end

    def ffengine_dir
      ".ffengine"
    end

    def move_ffengine_to_root
      puts run_with_err_output("echo Removing data directory from downloaded files; rm -rf #{ffengine_dir}/#{FFEngine_TOP_DIR}/data")

      puts run_with_err_output("echo Removing existing lib, bin, ffnsbin, module and scripts directories; rm -rf ./lib ./bin ./ffnsbin ./module ./scripts")
      puts run_with_err_output("echo Moving downloaded files into place; mv #{ffengine_dir}/#{FFEngine_TOP_DIR}/* . && rm -rf #{ffengine_dir}")
    end

    def copy_resources
      # copy ffengine configuration updates into place
      run_with_err_output("cp -r #{File.expand_path('../../../resources/ffengine', __FILE__)}/* #{build_path}")
    end

    def default_process_types
      {
        "web" => "./bin/ff-service cl"
      }
    end
  end
end
