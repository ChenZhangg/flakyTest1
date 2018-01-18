require 'git'
require 'travis'
require 'date'
begin
  travis_repo=Travis::Repository.find('naparuba/shinken')
  first_commit=travis_repo.build(1).commit
  first_sha=first_commit.sha
  start_date=first_commit.committed_at
rescue Exception=>e
  retry
end
p start_date
p start_date.class
p start_date.getlocal
p Time.now
p Time.now.class
days=(Time.now.to_date-start_date.getlocal.to_date).to_i
p days
puts first_sha
g=Git.open('/home/zc/projects/shinken')
p g.index
p g.repo
p g.dir
g_log=g.log(nil).since("#{days} days ago")
count=0
g_log.reverse_each do |l|
  puts "#{l.sha} #{l.date}"
  result=%x"cd /home/zc/projects/shinken && git branch --contains=#{l.sha}"
  p result
  count+=1
end
puts count
puts g.branches
puts g.branches.local
puts g.branches.remote