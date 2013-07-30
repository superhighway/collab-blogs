json.post do
  json.extract! @post, :id, :user_id, :title, :content, :created_at, :updated_at
  json.web_url post_url(@post)
  json.url post_url(@post, format: :json)
  json.collaborators(@post.collaborators) do |collaborator|
  	json.extract! collaborator, :id, :email
  end
end
