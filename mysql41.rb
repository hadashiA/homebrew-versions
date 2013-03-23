require 'formula'

class Mysql41 < Formula
  homepage 'http://download.softagency.net/MySQL/Downloads/MySQL-4.1/'
  url 'http://download.softagency.net/MySQL/Downloads/MySQL-4.1/mysql-4.1.22.tar.gz'
  sha1 '857e942cc3207caf56e2aa48961fc1ed66d932e6'

  depends_on 'readline'

  conflicts_with 'mariadb',
    :because => "mysql and mariadb install the same binaries."

  conflicts_with 'percona-server',
    :because => "mysql and percona-server install the same binaries."

  conflicts_with 'mysql-cluster',
    :because => "mysql and mysql-cluster install the same binaries."

  fails_with :clang do
    build 425
    cause <<-EOS.undent
      /usr/include/sys/socket.h:610:5: note: candidate function not viable: no known conversion from 'size_socket *' (aka 'int *') to 'socklen_t *' (aka 'unsigned int *') for 3rd argument
int   accept(int, struct sockaddr * __restrict, socklen_t * __restrict)
        ^
    EOS
  end

  def install
    # Make sure the var/mysql directory exists
    (var+"mysql").mkpath

    system "./configure",
      "--prefix=#{prefix}",
      "--with-charset=utf8",
      "--with-collation=utf8_general_ci",
      "--sysconfdir=#{etc}",
      "--datadir=#{var}",
      "--localstatedir=#{var}/mysql",
      "--mandir=#{man}",
      "--infodir=#{info}",
      "--without-readline",
      "--without-libedit"
    system "make"
    system "make install"

    prefix.install Dir['support-files']
    chmod 0755, "#{prefix}/support-files/mysql.server"
    inreplace "#{prefix}/support-files/mysql.server" do |s|
      s.gsub!(/^(PATH="?.*)("?)/, "\\1:#{HOMEBREW_PREFIX}/bin\\2")
    end
    ln_s "#{prefix}/support-files/mysql.server", bin
  end

  def caveats; <<-EOS.undent
    Set up databases to run AS YOUR USER ACCOUNT with:
        unset TMPDIR
        mysql_install_db --verbose --user=`whoami` --basedir="/usr/local/opt/mysql41" --datadir=#{var}/mysql --tmpdir=/tmp

    To set up base tables in another folder, or use a different user to run
    mysqld, view the help for mysqld_install_db:
        mysql_install_db --help

    and view the MySQL documentation:
      * http://dev.mysql.com/doc/refman/4.1/ja/mysql-install-db.html
      * http://dev.mysql.com/doc/refman/4.1/ja/default-privileges.html

    To run as, for instance, user "mysql", you may need to `sudo`:
        sudo mysql_install_db ...options...

    A "/etc/my.cnf" from another install may interfere with a Homebrew-built
    server starting up correctly.

    To connect:
        mysql -uroot
    EOS
  end

  plist_options :manual => "mysql.server start"

  def plist; <<-EOS.undent
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>KeepAlive</key>
      <true/>
      <key>Label</key>
      <string>#{plist_name}</string>
      <key>Program</key>
      <string>#{opt_prefix}/bin/mysqld_safe</string>
      <key>RunAtLoad</key>
      <true/>
      <key>UserName</key>
      <string>#{`whoami`.chomp}</string>
      <key>WorkingDirectory</key>
      <string>#{var}</string>
    </dict>
    </plist>
    EOS
  end
end
