MRuby::Gem::Specification.new('mruby-libssl-static') do |spec|
  spec.license = 'MIT'
  spec.authors = 'zzak'

  #build.linker.libraries << 'libssl'
  #build.linker.libraries << 'dl'
  require 'open3'

  openssl_version  = "1.1.0"
  openssl_url      = "https://www.openssl.org/source"
  openssl_package  = "openssl-#{openssl_version}.tar.gz"

  openssl_dir      = "#{build_dir}/openssl-#{openssl_version}"

  def run_command env, command
    STDOUT.sync = true
    puts "build: [exec] #{command}"
    Open3.popen2e(env, command) do |stdin, stdout, thread|
      print stdout.read
      fail "#{command} failed" if thread.value != 0
    end
  end

  FileUtils.mkdir_p build_dir

  if ! File.exists? openssl_dir
    Dir.chdir(build_dir) do
      e = {}
      run_command e, "curl #{openssl_url}/#{openssl_package} | tar -xzv"
      run_command e, "mkdir #{openssl_dir}/build"
    end
  end

  if ! File.exists? "#{openssl_dir}/build/lib/libssl.a"
    Dir.chdir openssl_dir do
      e = {
        'CC' => "#{build.cc.command} #{build.cc.flags.join(' ')}",
        'CXX' => "#{build.cxx.command} #{build.cxx.flags.join(' ')}",
        'LD' => "#{build.linker.command} #{build.linker.flags.join(' ')}",
        'AR' => build.archiver.command
      }

      configure_opts = ["--prefix=#{openssl_dir}/build", "no-shared"]
      if build.kind_of?(MRuby::CrossBuild) && build.host_target && build.build_target
        configure_opts += %W(--host #{build.host_target} --build #{build.build_target})
      end
      run_command e, "./config #{configure_opts.join(" ")}"
      run_command e, "make"
      run_command e, "make install_sw"
    end
  end

  build.cc.include_paths << "#{openssl_dir}/build/include"
  build.linker.library_paths << "#{openssl_dir}/build/lib/"
end
