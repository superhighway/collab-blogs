require 'spec_helper'

describe PostsController do
  fixtures :users, :posts

  describe "#index" do
    def expect_successful_request
      get :index
      response.should be_success
    end

    it "works for a guest user" do
      expect_successful_request
    end

    it "works for a logged in user" do
      sign_in users(:four)
      expect_successful_request
    end

    it "works for an admin user" do
      sign_in users(:admin)
      expect_successful_request
    end
  end

  describe "#new" do
    def perform_request
      get :new
    end

    def expect_successful_request
      perform_request
      response.should be_success
    end

    it "redirects to sign in page for a guest user" do
      perform_request
      response.should redirect_to(new_user_session_path)
    end

    it "works for a logged in user" do
      sign_in users(:four)
      expect_successful_request
    end

    it "works for an admin user" do
      sign_in users(:admin)
      expect_successful_request
    end
  end

  describe "#create" do
    def perform_request
      post :create, post: { title: "title hello world", content: "content hello world" }
    end

    it "redirects to sign in page for a guest user" do
      expect {
        perform_request
      }.not_to change(Post, :count)
      response.should redirect_to(new_user_session_path)
    end

    it "works for a logged in user" do
      sign_in users(:four)

      expect {
        perform_request
      }.to change(Post, :count).by(1)
      response.should redirect_to(post_path(Post.last))
    end

    it "works for an admin user" do
      sign_in users(:admin)

      expect {
        perform_request
      }.to change(Post, :count).by(1)
      response.should redirect_to(post_path(Post.last))
    end
  end

  describe "#edit" do
    let(:edited_post) { posts(:three) }
    def perform_request
      get :edit, id: edited_post
    end

    it "redirects to sign in page for a guest user" do
      perform_request
      response.should redirect_to(new_user_session_path)
    end

    it "works for the post's creator" do
      sign_in users(:three)

      perform_request
      response.should be_success
    end

    it "works for post's collaborator" do
      collaborator = users(:four)
      edited_post.collaborators << collaborator
      sign_in collaborator
      perform_request
      response.should be_success
    end

    it "is unauthorized for other users" do
      sign_in users(:four)

      perform_request
      response.should be_forbidden
    end

    it "works for an admin user" do
      sign_in users(:admin)
      
      perform_request
      response.should be_success
    end
  end

  describe "#update" do
    let(:updated_post) { posts(:three) }

    def perform_request
      patch :update, id: updated_post.id, post: { content: "hello hello", title: "test test" }
    end

    it "redirects to sign in page for a guest user" do
      perform_request
      response.should redirect_to(new_user_session_path)
    end

    it "works for the post's creator" do
      sign_in users(:three)

      perform_request
      response.should redirect_to(updated_post)
    end

    it "works for post's collaborator" do
      collaborator = users(:four)
      updated_post.collaborators << collaborator
      sign_in collaborator
      perform_request
      response.should redirect_to(updated_post)
    end

    it "is unauthorized for other users" do
      sign_in users(:four)

      perform_request
      response.should be_forbidden
    end

    it "works for an admin user" do
      sign_in users(:admin)
      
      perform_request
      response.should redirect_to(updated_post)
    end
  end

  describe "#destroy" do
    def perform_request
      delete :destroy, id: posts(:three)
    end

    it "redirects to sign in page for a guest user" do
      expect {
        perform_request
      }.not_to change(Post, :count)
      response.should redirect_to(new_user_session_path)
    end

    it "works for the post's owner" do
      sign_in users(:three)

      expect {
        perform_request
      }.to change(Post, :count).by(-1)
      response.should redirect_to(posts_path)
    end

    it "is unauthorized for other users" do
      sign_in users(:four)

      expect {
        perform_request
      }.not_to change(Post, :count)
      response.should be_forbidden
    end

    it "works for an admin user" do
      sign_in users(:admin)

      expect {
        perform_request
      }.to change(Post, :count).by(-1)
      response.should redirect_to(posts_path)
    end
  end
end
