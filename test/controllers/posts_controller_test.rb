require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  setup do
    @user = users(:one)
    @post = posts(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:posts)
  end

  test "should get new if authorized" do
    sign_in @user
    get :new
    assert_response :success
  end

  test "should create post if authorized" do
    sign_in @user
    assert_difference('Post.count') do
      post :create, post: { content: @post.content, title: @post.title }
    end

    assert_redirected_to post_path(assigns(:post))
  end

  test "should show post" do
    get :show, id: @post
    assert_response :success
  end

  test "should get edit if authorized" do
    sign_in @user
    get :edit, id: @post
    assert_response :success
  end

  test "should update post if authorized" do
    sign_in @user
    patch :update, id: @post, post: { content: @post.content, title: @post.title }
    assert_redirected_to post_path(assigns(:post))
  end

  test "should destroy post if authorized" do
    sign_in @user
    assert_difference('Post.count', -1) do
      delete :destroy, id: @post
    end

    assert_redirected_to posts_path
  end

  # Guest user
  test "should sign in" do
    get :new
    assert_redirected_to new_user_session_path

    post :create, post: { content: @post.content, title: @post.title }
    assert_redirected_to new_user_session_path

    patch :update, id: @post, post: { content: @post.content, title: @post.title }
    assert_redirected_to new_user_session_path
  end

  # A user trying to access a restricted post
  # that is created by someone else
  test "should forbid unauthorized user" do
    @post.update_attribute(:restricted, true)
    @user = users(:two)
    sign_in @user

    patch :update, id: @post, post: { content: @post.content, title: @post.title }
    assert_response :forbidden
  end
end
