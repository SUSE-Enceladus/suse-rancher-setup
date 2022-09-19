require 'rails_helper'

RSpec.describe LoginController, :type => :controller do
  describe "show" do
    it "checks user validation" do
      expect_any_instance_of(User).to receive(:is_authorized?)
      get :show
    end

    it "redirects if authorized" do
      expect_any_instance_of(User).to receive(:is_authorized?).and_return(true)
      get :show
      expect(response).to redirect_to(welcome_path)
    end
  end

  describe "update" do
    it "authorizes" do
      expect_any_instance_of(User).to receive(:authorize!).and_call_original
      post :update, params: { user: { username: 'username', password: 'password' } }
      expect(response).to redirect_to(welcome_path)
    end

    it "redirects back if authorization fails" do
      expect_any_instance_of(User).to receive(:is_authorized?).and_return(false)
      post :update, params: { user: { username: 'username', password: 'password' } }
      expect(response).to redirect_to(root_path)
    end
  end
end
