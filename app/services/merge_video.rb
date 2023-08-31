require "open-uri"
require 'tmpdir'
require 'net/http'


  class MergeVideo
    def initialize(post, url)
      @url = url
      @post = post
      @folder_path = "#{Rails.root}/tmp/post/#{post.id}"
      @first_file_name = "A1080.mp4"
      @second_file_name = "B1080.mp4"
      @first_video_path = "#{@folder_path}/#{@first_file_name}"
      @second_video_path = "#{@folder_path}/#{@second_file_name}"
      @output_video_path = "#{@folder_path}/output.mp4"
      @text_file = "#{@folder_path}/input.txt"
    end

    def process
      create_directory
      input_text_file
       download_files
       merge_command
       save_video if File.exist?(@output_video_path)
       delete_temp_files
      {"message": "Video has merged"}
    end

    def create_directory
      Dir.mktmpdir(@folder_path) unless Dir.exist?(@folder_path)
  	end

  	def fan_url
  	  #'https://utsstadiumexperienceott-311237-ruby.b311237.dev.eastus.az.svc.builder.cafe/rails/active_storage/blobs/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBckVCIiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--d6f276bf9be2ca466e47b5906417668ec05e60c7/A1080.mp4?disposition=attachment'
  	  "#{@url}#{Rails.application.routes.url_helpers.rails_blob_url(@post.fan_video, disposition: "attachment", only_path: true)}"
  	end

  	def player_url
  		#'https://utsstadiumexperienceott-311237-ruby.b311237.dev.eastus.az.svc.builder.cafe/rails/active_storage/blobs/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBcklCIiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--ba1fcda465cb7de1bc93aca398666687d7529c4e/B1080.mp4?disposition=attachment'
  	  "#{@url}#{Rails.application.routes.url_helpers.rails_blob_url(@post.player_video, disposition: "attachment", only_path: true)}"
  	end

  	def input_text_file
  	  FileUtils.mkdir_p(File.dirname(@text_file))
  	  File.open(@text_file, 'w') do |file|
        # Write content to the file
        file.puts("file '#{@first_file_name}'")
        file.puts("file '#{@second_file_name}'")
      end
      puts File.exist?(@text_file)
  	end

    def download_files
 	  download_file(fan_url, @first_video_path) unless File.exist?(@first_video_path)
 	  download_file(player_url, @second_video_path) unless File.exist?(@second_video_path)
    end

    def download_file(url, path)

    	FileUtils.mkdir_p(File.dirname(path))
    	uri = URI(url)
    	response = nil
    	count = 0
    	loop do

		    response = Net::HTTP.get_response(uri)

		    if response.is_a?(Net::HTTPRedirection)
		      uri = URI(response['location'])  # Follow the redirect
		    else
		      break  # Break the loop if not a redirection
		    end
		    break if count == 2
		    count = count + 1

		end
        if response.is_a?(Net::HTTPSuccess)
          file_content = response.body
	        File.open(path, "wb") do |file|
	          file.write(file_content)
	        end
        end
        
    rescue StandardError => e
  		puts "An error occurred: #{e.message}"
    end

    def save_video
      @post.merge_video.attach(io: File.open(@output_video_path),
        filename: "video_#{Time.now.strftime('%Y%m%d_%H%M%S')}.mp4", content_type: 'video/mp4')
    end

    def merge_command
      system("ffmpeg -f concat -i #{@text_file} -c:v libx264 -crf 18 -c:a aac -strict experimental #{@output_video_path}")
    end

    def delete_temp_files
      FileUtils.remove_entry(@folder_path) if Dir.exist?(@folder_path)
    end
  end
