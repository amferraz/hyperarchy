class AppServer
  attr_reader :stage, :rails_env
  def initialize(stage)
    @stage = stage
    @rails_env = stage
  end

  def hostname
    'rails.hyperarchy.com'
  end

  def repository
    "git@github.com:nathansobo/hyperarchy.git"
  end

  def deploy(ref)
    system "thor deploy:minify_js"
    run "su - hyperarchy"
    run "cd /app"
    run "git fetch origin"
    run "git checkout --force", ref
    run "source .rvmrc"
    run "bundle install --deployment --without development test deploy"
    run "mkdir -p public/assets"
    Dir["public/assets/*"].each do |path|
      upload! path, "/app/public/assets/#{File.basename(path)}"
    end
    run "RAILS_ENV=#{rails_env} bundle exec rake db:migrate"
    run "exit"
    restart_service 'unicorn'
    restart_service 'resque_worker'
    restart_service 'resque_scheduler'
  end

  def provision
#    update_packages
#    create_hyperarchy_user
#    create_log_directory
#    install_package 'git-core'
#    install_daemontools
#    install_postgres
#    install_nginx
#    install_redis
#    install_rvm
#    install_ruby
#    upload_deploy_keys
#    clone_repository
    install_services
    puts
  end

  def install_public_key
    puts "enter root password for #{hostname}:"
    password = $stdin.gets.chomp
    ssh_session('root', password)
    run 'mkdir -p ~/.ssh'
    run "echo '#{File.read(public_key_path).chomp}' >> ~/.ssh/authorized_keys"
    puts
    system "ssh-add #{private_key_path}"
  end

  def private_key_path
    File.expand_path('keys/id_rsa')
  end

  def public_key_path
    File.expand_path('keys/id_rsa.pub')
  end

  def restart_service(service_name)
    run "rm /service/#{service_name}/down" if run?("test -e /service/#{service_name}/down")
    if run("svstat /service/#{service_name}") =~ /down \d/
      run "svc -u /service/#{service_name}"
    else
      run "svc -q /service/#{service_name}"
    end
  end

  def update_packages
    run "yes | apt-get update"
    run "yes | apt-get upgrade"
  end

  def create_hyperarchy_user
    run "mkdir /home/hyperarchy"
    run "useradd hyperarchy -d /home/hyperarchy -s /bin/bash"
    run "cp -r /root/.ssh /home/hyperarchy/.ssh"
  end

  def create_log_directory
    run "mkdir -p /log"
    run "chown hyperarchy /log"
  end

  def install_daemontools
    install_package 'build-essential'
    make_daemontools_dirs
    download_daemontools
    run "cd /package"
    run "tar -xzvpf /usr/local/djb/dist/daemontools-0.76.tar.gz"
    run "cd admin/daemontools-0.76"
    run "patch -p1 < /usr/local/djb/patches/daemontools-0.76.errno.patch"
    run "patch -p1 < /usr/local/djb/patches/daemontools-0.76.sigq12.patch"
    run "package/install"
    upload! 'lib/deploy/resources/daemontools/svscanboot.conf', '/etc/init/svscanboot.conf'
    run "start svscanboot"
  end

  def make_daemontools_dirs
    run "mkdir -p /usr/local/djb/dist"
    run "mkdir -p /usr/local/djb/patches"
    run "mkdir -p /usr/local/package"
    run "chmod 1755 /usr/local/package"
    run "ln -s /usr/local/package /package"
    run "mkdir /service"
    run "mkdir /var/svc.d"
  end

  def download_daemontools
    run "cd /usr/local/djb/dist"
    run "wget http://cr.yp.to/daemontools/daemontools-0.76.tar.gz"
    run "cd /usr/local/djb/patches"
    run "wget http://www.qmail.org/moni.csi.hu/pub/glibc-2.3.1/daemontools-0.76.errno.patch"
    run "wget http://thedjbway.b0llix.net/patches/daemontools-0.76.sigq12.patch"
  end

  def install_postgres
    install_packages 'postgresql', 'libpq-dev'
    run "su - postgres"
    run "pg_dropcluster --stop 8.4 main"
    run "pg_createcluster --start -e UTF-8 8.4 main"
    run "createuser hyperarchy --createdb --no-superuser --no-createrole"
    run "createdb --encoding utf8 --owner hyperarchy hyperarchy_#{rails_env}"
    run "exit"
  end

  def install_nginx
    install_packages 'libpcre3-dev', 'build-essential', 'libssl-dev'
    run "cd /opt"
    run "wget http://nginx.org/download/nginx-0.8.54.tar.gz"
    run "tar -zxvf nginx-0.8.54.tar.gz"
    run "cd /opt/nginx-0.8.54/"
    run "./configure --prefix=/opt/nginx --user=nginx --group=nginx --with-http_ssl_module"
    run "make"
    run "make install"
    run "adduser --system --no-create-home --disabled-login --disabled-password --group nginx"
    run "ln -s /opt/nginx/sbin/nginx /usr/local/sbin/nginx"
    upload! 'lib/deploy/resources/nginx/nginx.conf', '/opt/nginx/conf/nginx.conf'
    upload! 'lib/deploy/resources/nginx/nginx_upstart.conf', '/etc/init/nginx.conf'
    upload! 'lib/deploy/resources/nginx/hyperarchy.crt', '/etc/ssl/certs/hyperarchy.crt'
    upload! 'lib/deploy/resources/nginx/hyperarchy.key', '/etc/ssl/private/hyperarchy.key'
    run "start nginx"
  end

  def install_redis
    run "apt-get install redis-server"
  end

  def update_nginx_config
    upload! 'lib/deploy/resources/nginx/nginx.conf', '/opt/nginx/conf/nginx.conf'
    if run? "nginx -t"
      run "nginx -s reload"
    else
      puts "nginx config is not syntactically valid. not reloading it."
    end
  end

  def install_rvm
    run "bash < <(curl -s https://rvm.beginrescueend.com/install/rvm)"
    run "rvm get latest"
    run "source /usr/local/rvm/scripts/rvm"
    upload! 'lib/deploy/resources/.bashrc', '/root/.bashrc'
    run 'cp /root/.bashrc /home/hyperarchy/.bashrc'
  end

  def install_ruby
    install_packages *%w(
      build-essential bison openssl libreadline6 libreadline6-dev curl zlib1g zlib1g-dev libssl-dev
      libyaml-dev libsqlite3-0 libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev
    )
    run "rvm install 1.9.2-p180"
    run "rvm use 1.9.2-p180 --default"
    run "gem install bundler --version 1.0.12"
  end

  def upload_deploy_keys
    upload! "keys/deploy", "/root/.ssh/id_rsa"
    upload! "keys/deploy.pub", "/root/.ssh/id_rsa.pub"
    run "chmod 600 /root/.ssh/id_rsa*"
    run "cp /root/.ssh/id_rsa* /home/hyperarchy/.ssh"
    run "chown -R hyperarchy /home/hyperarchy/.ssh"
    run "chgrp -R hyperarchy /home/hyperarchy/.ssh"
  end

  def clone_repository
    run "mkdir /app"
    run "chown hyperarchy:hyperarchy /app"
    run "su - hyperarchy"
    run "ssh -o StrictHostKeyChecking=no git@github.com"
    run "yes | git clone", repository, "/app"
    run "ln -s /log /app/log"
    run "rvm rvmrc trust /app"
    run "exit"
  end

  def install_services
    install_service 'unicorn'
    install_service 'resque_worker', :QUEUE => '*', :VVERBOSE => 1
    install_service 'resque_scheduler'
  end

  def install_service(service_name, env_vars={})
    env_vars = {:RAILS_ENV => rails_env}.merge(env_vars)
    run "rm /service/#{service_name}" if run?("test -e /service/#{service_name}")
    if run?("test -e /var/svc.d/#{service_name}")
      run "svc -dx /var/svc.d/#{service_name} /var/svc.d/#{service_name}/log"
      run "rm -rf /var/svc.d/#{service_name}"
    end
    run "mkdir -p /log/#{service_name}"
    upload! "lib/deploy/resources/services/#{service_name}", "/var/svc.d/#{service_name}"
    run "chmod 755 /var/svc.d/#{service_name}/run"
    run "chmod 755 /var/svc.d/#{service_name}/#{service_name}.sh"
    run "chmod 755 /var/svc.d/#{service_name}/log/run"
    run "mkdir -p /var/svc.d/#{service_name}/env"
    env_vars.each do |var_name, value|
      run "echo", value, "> /var/svc.d/#{service_name}/env/#{var_name}"
    end
    run "touch /var/svc.d/#{service_name}/down"
    run "ln -s /var/svc.d/#{service_name} /service/#{service_name}"
  end

  protected

  def install_packages(*packages)
    run "yes | apt-get install", *packages
  end
  alias_method :install_package, :install_packages

  PROMPT_REGEX = /[$%#>] (\z|\e)/n
  def run(*command)
    command = command.join(' ')
    output = shell.cmd(command) {|data| print data.gsub(/(\r|\r\n|\n\r)+/, "\n") }
    command_regex = /#{Regexp.escape(command)}/
    output.split("\n").reject {|l| l.match(command_regex) || l.match(PROMPT_REGEX)}.join("\n")
  end

  def run?(command)
    run(command)
    run("echo $?") == '0'
  end

  class UploadProgressHandler
    def on_open(uploader, file)
      puts "starting upload: #{file.local} -> #{file.remote} (#{file.size} bytes)"
    end

    def on_put(uploader, file, offset, data)
      puts "writing #{data.length} bytes to #{file.remote} starting at #{offset}"
    end

    def on_close(uploader, file)
      puts "finished with #{file.remote}"
    end

    def on_mkdir(uploader, path)
      puts "creating directory #{path}"
    end
  end

  def upload!(from, to)
    sftp_session.upload!(from, to, :progress => UploadProgressHandler.new)
  end

  def shell
    @shell ||= Net::SSH::Telnet.new('Session' => ssh_session, 'Prompt' => PROMPT_REGEX)
  end

  def ssh_session(user="root", password=nil)
    @ssh_session ||= Net::SSH.start(hostname, user, :password => password)
  end

  def sftp_session
    @sftp_session ||= Net::SFTP::Session.new(ssh_session).tap do |sftp|
      sftp.loop { sftp.opening? }
    end
  end
end