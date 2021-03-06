require 'json'
require 'nokogiri'
require 'awesome_print'

require './pull_threads'
require './threads'

testing = false

# Get subset of threads for faster testing
# selected_threads = ThreadList::Threads.each_slice(40).map(&:last)
puts "Pulling threads (Testing: #{testing})"
if testing
	selected_threads = [ThreadList::Threads.first]
	@raw_threads = PullThreads.pull selected_threads
else
	@raw_threads = PullThreads.pull ThreadList::Threads 
end

output = File.open "json/data.json", 'w'

puts "#{@raw_threads.size} threads pulled. Processing."

output_count = 0
@raw_threads.each do |thread|
	thread_doc = Nokogiri::HTML(thread.html)
	begin
		posts = thread_doc.css('.GIURNSTDHEB').map do |post|
			summary = {
				author: post.css('._username').text,
				date: post.css('.GIURNSTDBEB')[0]["title"],
				corbitt: false,
				content: post.css('.GIURNSTDAEB')
			}
			summary[:corbitt] = true if summary[:author] == "Don Corbitt"
			summary
		end

		hash = {
			url: thread.url,
			list: thread.list,
			thread_id: thread.id,
			title: thread_doc.css('title').text[0..-17],
			date: posts.empty? ? nil : posts.first[:date],
			num_posts: posts.count,
			num_corbitt: posts.select{|p| p[:corbitt]}.count,
			posts: posts
		}
		# puts "#{thread.list}:#{thread.id} #{thread_doc.css('.GFLL15SNXB').text}, #{posts.count}" if hash[:num_posts] != posts.count
		if hash[:num_corbitt] > 0
			output.puts hash.to_json
			output_count += 1
		end
		puts hash if testing
	rescue
		puts "Bad thread"
	end
end

puts "#{output_count} threads successfully parsed"