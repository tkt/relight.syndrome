#add@tkt 2009/12/30 for access check
#To move data before the specified date.
$LOAD_PATH.unshift('./lib')
require 'fileutils'
require 'logger'
require 'config'
require 'ms/access'
BACKUP_DIR = '/backup/data/dir/name'
BACKUP_DB_DIR = BACKUP_DIR + '/db'
BACKUP_DB = BACKUP_DB_DIR + '/acceck_backup.db'

specified = ARGV.shift

if specified == nil || specified == ''
	specified = 30
end


logger = Logger.new('/backup/log/dir/name/acceck_backup.log')
logger.info('acceck_backup -- proccess start')
check = Access::Check.new('')

#before
print "before!\n"
#p check.selectAll()
print "\n"


#check backup db

Dir.mkdir(BACKUP_DIR) unless File.exist?(BACKUP_DIR)
Dir.mkdir(BACKUP_DB_DIR) unless File.exist?(BACKUP_DB_DIR)
FileUtils.copy(BACKUP_DB, BACKUP_DB + "_" + Time.now.strftime("%Y%m%d")) if File.exist?(BACKUP_DB)

backupdb = PStore.new(BACKUP_DB)
until File.exist?(BACKUP_DB) do
	backupdb.transaction {
	  backupdb['root'] = Array.new
	}
end

limitdate = specified.to_i * 60 * 60
now = Time.now

logger.info("acceck_backup -- now count:" + check.selectAll().size.to_s + " limit(day)F" + specified.to_s)

accessdb = PStore.new(S[:access_check_dbpath])

backupdb.transaction(false) {
	accessdb.transaction(false) {
		accessdb['root'].each {|target|
			 if check.timediff(now, target['time']) >= limitdate
				backupdata = Hash.new
				backupdata['time'] = target['time']
				backupdata['addr'] = target['addr']
				backupdb['root'].push(backupdata)
				
				#accessdb.delete(target)
			 end
		}
		
		accessdb['root'].delete_if {|target| check.timediff(now, target['time']) >= limitdate}
	}

}


print "result!\n"
#p check.selectAll()
print "\n"
logger.info("acceck_backup -- result count:" + check.selectAll().size.to_s)
logger.info('acceck_backup -- proccess end')