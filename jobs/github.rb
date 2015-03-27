require 'octokit'
require 'dotenv'

Dotenv.load

client = Octokit::Client.new(access_token: ENV["GITHUB_AUTH_TOKEN"])

SCHEDULER.every '10m', first_in: 0 do |job|
  additions     = 0
  deletions     = 0
  commit_count  = 0
  pr_count      = 0
  pull_requests = []

  users = ENV["GITHUB_STAT_USERS"]

  if users.nil?
    users = []
  else
    users = users.split("|")
  end

  today_midnight = DateTime.now
  today_midnight = DateTime.new(
    today_midnight.year,
    today_midnight.month,
    today_midnight.day,
    0, 0, 0)


  users.each do |user|
    repos = client.repos(user.to_sym, {type: :owner})

    repos.each do |repo|
      commits = client.commits_since(repo[:full_name], today_midnight)
      commit_count += commits.length

      prs = client.pull_requests(repo[:full_name], {
        state: "open",
        sort: "created",
        direction: "asc"
      })

      pull_requests += prs.map do |pr|
        {
          title: pr[:title],
          date: pr[:created_at],
          repo: repo[:full_name],
          user: pr[:user][:login]
        }
      end

      commits.each do |commit|
        c = client.commit(repo[:full_name], commit[:sha])

        additions += c[:stats][:additions]
        deletions += c[:stats][:deletions]
      end
    end
  end

  send_event("ghstats", { additions: additions, deletions: deletions, commits: commit_count, prs: pull_requests.length })

  send_event("pullrequests", { prs: pull_requests })
end

