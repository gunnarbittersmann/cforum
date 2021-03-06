# -*- coding: utf-8 -*-

require 'rails_helper'

RSpec.describe CitesController, type: :controller do
  let(:admin) { create(:cf_user_admin) }

  describe "GET #index" do
    it "assigns all cites as @cites" do
      cite = create(:cf_cite, archived: true)
      get :index, {}
      expect(assigns(:cites)).to eq([cite])
    end
  end

  describe "GET #new" do
    it "assigns a new cite as @cite" do
      get :new, {}
      expect(assigns(:cite)).to be_a_new(CfCite)
    end
  end

  describe "GET #show" do
    it "assigns the cite as @cite" do
      cite = create(:cf_cite)
      get :show, {id: cite.to_param}
      expect(assigns(:cite)).to eq(cite)
    end
  end

  describe "GET #edit" do
    it "assigns the requested cite as @cite" do
      cite = create(:cf_cite)
      sign_in admin

      get :edit, {id: cite.to_param}
      expect(assigns(:cite)).to eq(cite)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Cite" do
        expect {
          post :create, {cf_cite: attributes_for(:cf_cite)}
        }.to change(CfCite, :count).by(1)
      end

      it "assigns a newly created cite as @cite" do
        post :create, {cf_cite: attributes_for(:cf_cite)}
        expect(assigns(:cite)).to be_a(CfCite)
        expect(assigns(:cite)).to be_persisted
      end

      it "redirects to the index" do
        post :create, {cf_cite: attributes_for(:cf_cite)}
        expect(response).to redirect_to(cite_url(assigns(:cite)))
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved cite as @cite" do
        post :create, {cf_cite: {author: 'Lea'}}
        expect(assigns(:cite)).to be_a_new(CfCite)
      end

      it "re-renders the 'new' template" do
        post :create, {cf_cite: {author: 'Lea'}}
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      it "updates the requested cite" do
        sign_in admin

        cite = create(:cf_cite)
        new_cite = attributes_for(:cf_cite)

        put :update, {id: cite.to_param, cf_cite: new_cite}
        cite.reload

        expect(cite.author).to eq new_cite[:author]
        expect(cite.cite).to eq new_cite[:cite]
      end

      it "assigns the requested cite as @cite" do
        sign_in admin

        cite = create(:cf_cite)
        put :update, {id: cite.to_param, cf_cite: attributes_for(:cf_cite)}
        expect(assigns(:cite)).to eq(cite)
      end

      it "redirects to the cite" do
        sign_in admin

        cite = create(:cf_cite)
        put :update, {id: cite.to_param, cf_cite: attributes_for(:cf_cite)}
        expect(response).to redirect_to(cite_url(cite))
      end
    end

    context "with invalid params" do
      it "assigns the cite as @cite" do
        sign_in admin

        cite = create(:cf_cite)
        put :update, {id: cite.to_param, cf_cite: {cite: ''}}
        expect(assigns(:cite)).to eq(cite)
      end

      it "re-renders the 'edit' template" do
        sign_in admin

        cite = create(:cf_cite)
        put :update, {id: cite.to_param, cf_cite: {cite: ''}}
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested cite" do
      cite = create(:cf_cite)
      sign_in admin

      expect {
        delete :destroy, {id: cite.to_param}
      }.to change(CfCite, :count).by(-1)
    end

    it "redirects to the cites list" do
      cite = create(:cf_cite)
      sign_in admin

      delete :destroy, {id: cite.to_param}
      expect(response).to redirect_to(cites_url)
    end
  end

end
