require "spec_helper"

describe CanvasUserProvisionController do

  describe "#user_import" do
    let(:user_id_string)     { "1234,1235" }

    context "if session user not present" do
      before { session[:user_id] = nil }
      it "returns empty hash" do
        post :user_import, user_ids: user_id_string
        expect(response.status).to eq(200)
        expect(response.body).to eq "{}"
      end
    end

    context "if session user is not an admin" do
      before do
        session[:user_id] = "2050"
        User::Auth.stub(:where).and_return([User::Auth.new(uid: "2050", is_superuser: false, active: true)])
      end

      it "returns 403 error" do
        post :user_import, user_ids: user_id_string
        expect(response.status).to eq(403)
        expect(response.body).to eq " "
      end
    end

    context "if admin user authenticated" do
      before do
        session[:user_id] = "2050"
        User::Auth.stub(:where).and_return([User::Auth.new(uid: "2050", is_superuser: true, active: true)])
        Canvas::UserProvision.any_instance.stub(:import_users).and_return(true)
      end

      it "returns success response" do
        post :user_import, user_ids: user_id_string
        expect(response.status).to eq(200)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq "success"
        expect(json_response['user_ids']).to eq ["1234","1235"]
      end

      context "if StandardError exception raised" do
        it "returns error response" do
          Canvas::UserProvision.any_instance.stub(:import_users).and_raise(RuntimeError, "User import failed")
          post :user_import, user_ids: user_id_string
          expect(response.status).to eq(500)
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to eq "User import failed"
        end
      end

    end

  end

end
