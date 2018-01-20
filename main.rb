require 'git'
require 'csv'
require 'fileutils'
require 'travis'
require 'open4'
require 'date'
require 'travis/client'

@number_of_repositories=1
@client = Travis::Client.new

def clone_repo(user_dir,repo_url,repo_dir)
  i=0
  while(i<600)
    FileUtils.rm_rf(repo_dir) if File.exist?(repo_dir)
    result=%x"cd #{user_dir} && git clone #{repo_url}"
    if $?.to_i!=0
      puts "********************The #{i} of 600 try to clone the project from #{repo_url}. $?=#{$?.to_i}*******************************"
      i+=1
      sleep 60
      next
    else
      puts "*******************Clone the project from #{repo_url} successfully.**************************"
      break
    end
  end
end

def create_github_repo(repo_dir,user_name,repo_name,i)
  k=0
  while(i<600)
    %x"cd #{repo_dir} && hub create #{user_name}_#{repo_name}_#{i}"
    if $?.to_i!=0
      puts "*******************The #{k} of 600 try to hub create #{user_name}_#{repo_name}_#{i}. $?=#{$?.to_i}*******************************"
      k+=1
      sleep 60
      next
    else
      puts "*******************Create repo ChenZhangg/#{user_name}_#{repo_name}_#{i} on Github successfully.**************************"
      break
    end
  end
end

def open_travis(repo_dir,user_name,repo_name,i)
  k=0
  while(k<600)
    %x"cd #{repo_dir} && travis enable -r ChenZhangg/#{user_name}_#{repo_name}_#{i}"
    if $?.to_i!=0
      puts "*******************The #{k} of 600 try to enable ChenZhangg/#{user_name}_#{repo_name}_#{i}. $?=#{$?.to_i}*******************************"
      k+=1
      sleep 60
      next
    else
      puts "*******************Enable travis ChenZhangg/#{user_name}_#{repo_name}_#{i} successfully.**************************"
      break
    end
  end
end

def link_remote(repo_dir,user_name,repo_name,i)
  k=0
  while(k<600)
    %x"cd #{repo_dir} && git remote add #{user_name}_#{repo_name}_#{i} git@github.com:ChenZhangg/#{user_name}_#{repo_name}_#{i}.git"
    if $?.to_i==0
      puts "*******************Remote add ChenZhangg/#{user_name}_#{repo_name}_#{i} successfully.**************************"
      break
    elsif $?.to_i==128
      puts "*******************Already add ChenZhangg/#{user_name}_#{repo_name}_#{i}.**************************"
      break
    else
      puts "*******************The #{k} of 600 try to remote add ChenZhangg/#{user_name}_#{repo_name}_#{i}. $?=#{$?.to_i}*******************************"
      k+=1
      sleep 60
      next
    end
  end
end

def enable_travis(repo_dir,user_name,repo_name)
  (0...@number_of_repositories).each do |i|
    create_github_repo(repo_dir,user_name,repo_name,i)
    sleep 60
    open_travis(repo_dir,user_name,repo_name,i)
    link_remote(repo_dir,user_name,repo_name,i)
  end
end

def get_last_build(user_name,repo_name,i)
  k=0
  begin
    @client.clear_cache!
    travis_repo= @client.repo("ChenZhangg/#{user_name}_#{repo_name}_#{i}")
    last=travis_repo.last_build
  rescue
    puts $!
    travis_repo=nil
    last=nil
    puts "*******************The #{k} of 10 try to get last build of ChenZhangg/#{user_name}_#{repo_name}_#{i}.**************************"
    sleep 60
    k+=1
    retry if k<10
  end
  return last
end

def pre_build_completed(user_name,repo_name,i)
  sleep 300
  last=get_last_build(user_name,repo_name,i)
  puts "*******************The information of last build of ChenZhangg/#{user_name}_#{repo_name}_#{i} is #{last ?last.number:'0'}********************"
  while(last && last.finished? != true)
    puts "*******************The last build #{last ?last.number:'0'} of ChenZhangg/#{user_name}_#{repo_name}_#{i} is not finished.********************"
    sleep 300
    last=get_last_build(user_name,repo_name,i)
  end
end

def push(repo_dir,user_name,repo_name,l,i)
  k=0
  while(k<5)
    %x"cd #{repo_dir} && git push #{user_name}_#{repo_name}_#{i} #{l.sha}:refs/heads/master"
    if $?.to_i==0
      puts "*******************Push #{l.sha}  #{l.date} to Github repo ChenZhangg/#{user_name}_#{repo_name}_#{i}*******************"
      break
    elsif $?.to_i==256
      puts "*******************Push Error $?=#{$?} #{l.sha}  #{l.date} to Github repo ChenZhangg/#{user_name}_#{repo_name}_#{i}*******************"
      k+=1
      sleep 60
      next
    elsif $?.to_i==32768
      puts "*******************Push Error $?=#{$?.to_i} #{l.sha}  #{l.date} to Github repo ChenZhangg/#{user_name}_#{repo_name}_#{i}*******************"
      k+=1
      sleep 60
      next
    else
      puts "*******************Push Error $?=#{$?.to_i} #{l.sha}  #{l.date} to Github repo ChenZhangg/#{user_name}_#{repo_name}_#{i}*******************"
      k+=1
      sleep 60
      next
    end
  end
end

def git_push(repo_dir,user_name,repo_name,first_commit_time)
  days=(Time.now.to_date-first_commit_time.getlocal.to_date).to_i
  g=Git.open(repo_dir)
  g_log=g.log(nil).since("#{days} days ago")
  g_log.reverse_each do |l|
    (0...@number_of_repositories).each do |i|
      push(repo_dir,user_name,repo_name,l,i)
    end
    (0...@number_of_repositories).each do |i|
      pre_build_completed(user_name,repo_name,i)
    end
  end
end

def create_dir(user_name,repo_name,repo_url,first_commit_time)
  user_dir=File.join('repositories',user_name)
  repo_dir=File.join('repositories',user_name,repo_name)
  return if File.exist?(repo_dir)
  FileUtils.mkdir_p(user_dir) unless File.exist?(user_dir)
  clone_repo(user_dir,repo_url,repo_dir)
  enable_travis(repo_dir,user_name,repo_name)
  git_push(repo_dir,user_name,repo_name,first_commit_time)
end

def use_travis(user_name,repo_name,repo_url)
  i=0
  begin
    travis_repo=@client.repo("#{user_name}/#{repo_name}")
  rescue
    travis_repo=nil
    puts $!
    puts "****************#{user_name}/#{repo_name} don't use travis service, the #{i} of 10 try.****************"
    sleep 60
    i+=1
    retry if i<10
  end
  if travis_repo && travis_repo.last_build && travis_repo.last_build.number.to_i>10
    first_commit_time=travis_repo.build(1).commit.committed_at
    create_dir(user_name,repo_name,repo_url,first_commit_time)
  end
  puts "****************The project #{user_name}/#{repo_name} finished.***************************"
end


def csv_traverse(csv_file)
  CSV.foreach(csv_file,headers:false,col_sep:',') do |row|
    use_travis(row[0],row[1],row[2])
  end
  puts '***********************CSV TRAVERSE OVER**************************'
end
csv_traverse(ARGV[0])
#csv_traverse('java_github_repo.csv')

