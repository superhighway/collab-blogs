require 'spec_helper'
require 'cancan/matchers'

describe Ability do
  fixtures :users, :posts

  subject { Ability.new(user) }
  let(:user) { users(:three) }
  let(:restricted_post) { Post.new(user: user, restricted: true) }

  describe "an admin user" do
    before do
      user.admin = true
    end

    it { should be_able_to(:manage, :all) }
  end

  describe "a logged-in user" do
    it { should be_able_to(:new, Post) }
    it { should be_able_to(:create, Post.new) }
    it { should be_able_to(:destroy, Post.new(user: user)) }
    it { should_not be_able_to(:destroy, Post.new(user: users(:four))) }
    it { should be_able_to(:index, Post.new(user: user)) }
    it { should be_able_to(:index, restricted_post) }
    it { should be_able_to(:show, Post.new(user: user)) }
    it { should be_able_to(:show, Post.new(user: user, restricted: true)) }
    it { should_not be_able_to(:index, Post.new(user: users(:four), restricted: true)) }
    it { should_not be_able_to(:show, Post.new(user: users(:four), restricted: true)) }
    it { should be_able_to(:edit, posts(:three)) }
    it { should be_able_to(:update, posts(:three)) }
    it { should be_able_to(:update, posts(:three)) }

    describe "collaboration" do
      let(:collab_post) {
        post = posts(:four)
        post.collaborations << Collaboration.new(user_id: user.id, post_id: post.id)
        post
      }

      context "as a collaborator logged-in user" do
        # alternatively:
        # it { subject.should be_able_to(:index, post) }
        it { should be_able_to(:index, collab_post) }

        it { should be_able_to(:show, collab_post) }
        it { should be_able_to(:update, collab_post) }
        it { should be_able_to(:edit, collab_post) }
        it { should_not be_able_to(:destroy, collab_post) }
      end

      context "as a guest user" do
        let(:subject) { Ability.new nil }

        it { should be_able_to(:index, collab_post) }
        it { should be_able_to(:show, collab_post) }
        it { should_not be_able_to(:update, collab_post) }
        it { should_not be_able_to(:edit, collab_post) }
        it { should_not be_able_to(:destroy, collab_post) }
      end

      describe "restricted post" do
        context "as a collaborator" do
          let(:collab_post) {
            post = posts(:four)
            post.restricted = true
            post.collaborations << Collaboration.new(user_id: user.id, post_id: post.id)
            post
          }

          it { should be_able_to(:index, collab_post) }
          it { should be_able_to(:show, collab_post) }
          it { should be_able_to(:update, collab_post) }
          it { should be_able_to(:edit, collab_post) }
          it { should_not be_able_to(:destroy, collab_post) }
        end
      end
    end
  end

  describe "a guest user" do
    subject { Ability.new nil }

    it { should be_able_to(:index, posts(:four)) }
    it { should be_able_to(:show, posts(:four)) }
    it { should_not be_able_to(:new, Post) }
    it { should_not be_able_to(:create, Post.new) }
    it { should_not be_able_to(:edit, posts(:four)) }
    it { should_not be_able_to(:update, posts(:four)) }
    it { should_not be_able_to(:destroy, posts(:four)) }

    it { should_not be_able_to(:index, restricted_post) }
    it { should_not be_able_to(:show, restricted_post) }
  end
end
