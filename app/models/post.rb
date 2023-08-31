class Post < ApplicationRecord
	has_one_attached :fan_video
	has_one_attached :player_video
	has_one_attached :merge_video
end
