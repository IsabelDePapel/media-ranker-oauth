require 'test_helper'

describe WorksController do
  describe "root is the same for logged in and not logged in" do
    it "succeeds with all media types" do
      # Precondition: there is at least one media of each category
      %w(album book movie).each do |category|
        Work.by_category(category).length.must_be :>, 0, "No #{category.pluralize} in the test fixtures"
      end

      get root_path
      must_respond_with :success
    end

    it "succeeds with one media type absent" do
      # Precondition: there is at least one media in two of the categories
      %w(album book).each do |category|
        Work.by_category(category).length.must_be :>, 0, "No #{category.pluralize} in the test fixtures"
      end

      # Remove all movies
      Work.by_category("movie").destroy_all

      get root_path
      must_respond_with :success
    end

    it "succeeds with no media" do
      Work.destroy_all
      get root_path
      must_respond_with :success
    end
  end

  describe "not logged in" do
    let(:mariner) { works(:mariner) }

    describe "index" do
      it "redirects to root_path" do
        get works_path
        must_respond_with :redirect
        must_redirect_to root_path
      end
    end

    describe "show" do
      it "redirects to root path" do
        get work_path(mariner)
        must_respond_with :redirect
        must_redirect_to root_path
      end
    end

    describe "new" do
      it "redirects to root path" do
        get new_work_path
        must_respond_with :redirect
        must_redirect_to root_path
      end
    end

    describe "edit" do
      it "redirects to root path" do
        get edit_work_path(mariner)
        must_respond_with :redirect
        must_redirect_to root_path
      end
    end

    describe "destroy" do
      it "redirects to root path" do
        start_count = Work.count

        delete work_path(mariner)

        must_respond_with :redirect
        must_redirect_to root_path
        Work.count.must_equal start_count
      end
    end

    describe "upvote" do
      it "redirects to root path" do
        start_count = Vote.count

        post upvote_path(mariner)

        must_respond_with :redirect
        must_redirect_to root_path
        Vote.count.must_equal start_count
      end
    end
  end

  CATEGORIES = %w(albums books movies)
  INVALID_CATEGORIES = ["nope", "42", "", "  ", "albumstrailingtext"]

  describe "logged in" do
    before do
      @user = users(:kari)
      login(@user, :google_oauth2)
    end

    describe "index" do
      it "succeeds when there are works" do
        Work.count.must_be :>, 0, "No works in the test fixtures"
        get works_path
        must_respond_with :success
      end

      it "succeeds when there are no works" do
        Work.destroy_all
        get works_path
        must_respond_with :success
      end
    end

    describe "new" do
      it "works" do
        get new_work_path
        must_respond_with :success
      end
    end

    describe "create" do
      it "creates a work with valid data for a real category" do
        work_data = {
          work: {
            title: "test work"
          }
        }
        CATEGORIES.each do |category|
          work_data[:work][:category] = category

          start_count = Work.count

          post works_path(category), params: work_data
          must_redirect_to work_path(Work.last)

          Work.count.must_equal start_count + 1
        end
      end

      it "renders bad_request and does not update the DB for bogus data" do
        work_data = {
          work: {
            title: ""
          }
        }
        CATEGORIES.each do |category|
          work_data[:work][:category] = category

          start_count = Work.count

          post works_path(category), params: work_data
          must_respond_with :bad_request

          Work.count.must_equal start_count
        end
      end

      it "renders 400 bad_request for bogus categories" do
        work_data = {
          work: {
            title: "test work"
          }
        }
        INVALID_CATEGORIES.each do |category|
          work_data[:work][:category] = category

          start_count = Work.count

          post works_path(category), params: work_data
          must_respond_with :bad_request

          Work.count.must_equal start_count
        end
      end
    end

    describe "show" do
      it "succeeds for an extant work ID" do
        get work_path(Work.first)
        must_respond_with :success
      end

      it "renders 404 not_found for a bogus work ID" do
        bogus_work_id = Work.last.id + 1
        get work_path(bogus_work_id)
        must_respond_with :not_found
      end
    end

    describe "edit" do
      it "succeeds if user created the work" do
        new_work = Work.create!(title: "new work", user_id: @user.id, category: "book")
        get edit_work_path(new_work)
        must_respond_with :success
      end

      it "redirects if user didn't create the work" do
        get edit_work_path(Work.first)
        must_respond_with :redirect
      end

      it "renders 404 not_found for a bogus work ID" do
        bogus_work_id = Work.last.id + 1
        get edit_work_path(bogus_work_id)
        must_respond_with :not_found
      end
    end

    describe "update" do
      it "succeeds for valid data and an extant work ID" do
        work = Work.first
        work_data = {
          work: {
            title: work.title + " addition"
          }
        }

        patch work_path(work), params: work_data
        must_redirect_to work_path(work)

        # Verify the DB was really modified
        Work.find(work.id).title.must_equal work_data[:work][:title]
      end

      it "renders bad_request for bogus data" do
        work = Work.first
        work_data = {
          work: {
            title: ""
          }
        }

        patch work_path(work), params: work_data
        must_respond_with :not_found

        # Verify the DB was not modified
        Work.find(work.id).title.must_equal work.title
      end

      it "renders 404 not_found for a bogus work ID" do
        bogus_work_id = Work.last.id + 1
        get work_path(bogus_work_id)
        must_respond_with :not_found
      end
    end

    describe "destroy" do
      it "succeeds for an extant work ID if the user added the work" do
        new_work = Work.create!(title: "new work", user_id: @user.id, category: "book")

        delete work_path(new_work)
        must_redirect_to root_path

        # The work should really be gone
        Work.find_by(id: new_work.id).must_be_nil
      end

      it "redirects for an extant work ID if the user didn't add the work" do
        start_count = Work.count

        delete work_path(Work.first)

        must_respond_with :redirect
        Work.count.must_equal start_count
      end

      it "renders 404 not_found and does not update the DB for a bogus work ID" do
        start_count = Work.count

        bogus_work_id = Work.last.id + 1
        delete work_path(bogus_work_id)
        must_respond_with :not_found

        Work.count.must_equal start_count
      end
    end

    describe "upvote" do
      let(:user) { User.create!(username: "test_user", email: "test@user.com", uid: 1, provider: :github) }
      let(:work) { Work.last }

      # def login
      #   post login_path, params: { username: user.username }
      #   must_respond_with :redirect
      # end
      #
      def logout
        post logout_path
        must_respond_with :redirect
      end

      # already tested in nt logged in section
      # it "returns 401 unauthorized if no user is logged in" do
      #   logout
      #   start_vote_count = work.votes.count
      #
      #   post upvote_path(work)
      #   must_respond_with :unauthorized
      #
      #   work.votes.count.must_equal start_vote_count
      # end

      it "returns 401 unauthorized after the user has logged out" do
        start_vote_count = work.votes.count

        # login
        logout

        post upvote_path(work)
        # must_respond_with :unauthorized
        must_respond_with :redirect

        work.votes.count.must_equal start_vote_count
      end

      it "succeeds for a logged-in user and a fresh user-vote pair" do
        start_vote_count = work.votes.count

        # login

        post upvote_path(work)
        # Should be a redirect_back
        must_respond_with :redirect

        work.reload
        work.votes.count.must_equal start_vote_count + 1
      end

      it "returns 409 conflict if the user has already voted for that work" do
        # login
        Vote.create!(user: @user, work: work)

        start_vote_count = work.votes.count

        post upvote_path(work)
        must_respond_with :conflict

        work.votes.count.must_equal start_vote_count
      end
    end
  end
end
