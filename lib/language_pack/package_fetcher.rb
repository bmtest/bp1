require "net/http"
require "uri"
require "base64"

module LanguagePack
  module PackageFetcher

    VENDOR_URL = "http://download.run.pivotal.io/openjdk/lucid/x86_64"
    PACKAGES_CONFIG = File.join(File.dirname(__FILE__), "../../config/packages.yml")

    attr_writer :buildpack_cache_dir

    def buildpack_cache_dir
      @buildpack_cache_dir || "/var/vcap/packages/buildpack_cache"
    end

    def fetch_jdk_package(version)
      fetch_from_buildpack_cache("openjdk-1.7.0_65.tar.gz")
      fetch_from_curl("openjdk-1.7.0_65.tar.gz", VENDOR_URL)
    end

    def fetch_package(filename, url=VENDOR_URL)
      fetch_from_buildpack_cache(filename) ||
      fetch_from_curl(filename, url)
    end

    def fetch_package_and_untar(filename, url=VENDOR_URL)
      fetch_package(filename, url) && run("tar xzf #{filename}")
    end

    def packages_config
      YAML.load_file(File.expand_path(PACKAGES_CONFIG))
    end

    private

    def fetch_from_buildpack_cache(filename)
      puts "Looking for #{filename} in the buildpack cache ..."
      file_path = File.join(buildpack_cache_dir, filename)
      return unless File.exist?(file_path)
      puts "Copying #{filename} from the buildpack cache ..."
      FileUtils.cp(file_path, ".")
      File.expand_path(File.join(".", filename))
    end

    def fetch_from_curl(filename, url)
      puts "fetch_from_curl Downloading #{filename} from #{url} ..."
      system("curl #{url}/#{filename} -s -o #{filename}")
      puts "fetch_from_curl Downloaded #{filename} from #{url} ..."
      File.exist?(filename) ? filename : nil
    end

    def file_checksum(filename)
      Digest::SHA1.file(filename).hexdigest
    end
  end
end
