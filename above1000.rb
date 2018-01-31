require 'csv'
require 'travis'
def findRepository(repo)
  i=0
  begin
    travis_repo=Travis::Repository.find(repo)
  rescue
    travis_repo=nil
    puts "#{repo}, try #{i} times"
    i+=1
    #sleep 60
    #retry if i<5
  end
  if travis_repo && travis_repo.last_build && travis_repo.last_build.number.to_i>10
    return travis_repo.last_build.number.to_i
  else
    return 0
  end
end

def divide_user_repo(user_repo)
  pos=user_repo=~/\//
  return [user_repo[0...pos],user_repo[pos+1..-1]]
end

CSV.foreach('repoAbove1000.csv',headers:true,col_sep:',') do |row|
  File.open('repoAbove1000WithTravis.csv','a+') do |file|
    CSV(file,col_sep:',') do |csv|
      lastBuildNumber=findRepository(row[0][19..-1])
      user_name,repo_name=divide_user_repo(row[0][19..-1])
      puts "#{user_name} #{repo_name} #{row[0]},#{row[1]},#{lastBuildNumber}"
      csv<<[user_name,repo_name,row[0],row[1],lastBuildNumber] if lastBuildNumber>=1000
    end
  end
end
