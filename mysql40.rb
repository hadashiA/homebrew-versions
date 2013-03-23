require 'formula'

class Mysql40 < Formula
  homepage 'http://mirror.provenscaling.com/mysql/community/source/4.0/'
  url 'http://mirror.provenscaling.com/mysql/community/source/4.0/mysql-4.0.25.tar.gz'
  sha1 '65315c7659c75fcc9f3d9f749dbed26581f6da9c'

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

  def patches
    DATA
  end

  def install
    # Make sure the var/mysql directory exists
    (var+"mysql").mkpath

    system "./configure",
      "--prefix=#{prefix}",
      "--with-charset=ujis", 
      "--sysconfdir=#{etc}",
      "--datadir=#{var}",
      "--localstatedir=#{var}/mysql",
      "--mandir=#{man}",
      "--infodir=#{info}",
      "--without-readline"
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

        mysql_install_db --verbose --user=`whoami` --basedir="/usr/local/opt/mysql40" --datadir=/usr/local/var/mysql --tmpdir=/tmp

    To set up base tables in another folder, or use a different user to run
    mysqld, view the help for mysqld_install_db:
        mysql_install_db --help

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

__END__
diff --git a/include/my_global.h b/include/my_global.h
index e2a9766..368f36d 100644
--- a/include/my_global.h
+++ b/include/my_global.h
@@ -344,8 +344,8 @@ int  __void__;
 
 /* Define some useful general macros */
 #if defined(__cplusplus) && defined(__GNUC__)
-#define max(a, b)	((a) >? (b))
-#define min(a, b)	((a) <? (b))
+#define max(a, b)	((a) > (b) ? (a) : (b))
+#define min(a, b)	((a) < (b) ? (a) : (b))
 #elif !defined(max)
 #define max(a, b)	((a) > (b) ? (a) : (b))
 #define min(a, b)	((a) < (b) ? (a) : (b))
