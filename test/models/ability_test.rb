require 'test_helper'

class AbilityTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @ability = Ability.new(@user) 
  end

  test "user can destroy his/her own post" do
    assert @ability.can?(:destroy, Post.new(user: @user))
    assert @ability.cannot?(:destroy, Post.new)

    another_user = users(:two)
    assert @ability.cannot?(:destroy, Post.new(user: another_user))
  end

  test "user can view his/her own post" do
    assert @ability.can?(:index, Post.new(user: @user))
    assert @ability.can?(:index, Post.new(user: @user, restricted: true))
    assert @ability.can?(:show, Post.new(user: @user))
    assert @ability.can?(:show, Post.new(user: @user, restricted: true))
  end

  test "user cannot see other user's restricted post" do
    another_user = users(:two)
    assert @ability.cannot?(:index, Post.new(user: another_user, restricted: true))
  end

  test "can see another user's restricted post as a collaborator" do
    post = posts(:two)
    post.restricted = true
    post.collaborations << Collaboration.new(user_id: @user.id, post_id: post.id)
    assert @ability.can?(:index, post)
  end
end
