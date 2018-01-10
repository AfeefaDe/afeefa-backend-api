require 'test_helper'

class Api::V1::ChaptersControllerTest < ActionController::TestCase

  context 'as authorized user' do
    setup do
      @user = valid_user
      stub_current_user(user: @user)
    end

    should 'get empty list of chapters' do
      WebMock.stub_request(:get, "#{@controller.base_path}").to_return(body: '[]')

      get :index
      assert_response :ok, response.body
      json = JSON.parse(response.body)
      assert_equal [], json
    end

    should 'create chapter' do
      WebMock.stub_request(:post, "#{@controller.base_path}").to_return(status: 201, body: chapter.to_json)

      assert_difference -> { ChapterConfig.count } do
        assert_difference -> { AreaChapterConfig.count } do
          post :create, params: chapter.except(:id)
          assert_response :created, response.body
          assert_equal chapter.to_json, response.body
        end
      end

      WebMock.assert_requested(:post, "#{@controller.base_path}")
    end

    should 'handle error response on chapter create' do
      WebMock.stub_request(:post, "#{@controller.base_path}").to_return(status: 500, body: 'error')

      assert_no_difference -> { ChapterConfig.count } do
        assert_no_difference -> { AreaChapterConfig.count } do
          post :create, params: chapter.except(:id)
          assert_response :unprocessable_entity, response.body
          assert response.body.blank?
        end
      end

      WebMock.assert_requested(:post, "#{@controller.base_path}")
    end

    should 'update chapter' do
      assert chapter_config = ChapterConfig.create(chapter_id: chapter[:id])
      assert area_chapter_config = AreaChapterConfig.create(area: @user.area, chapter_config_id: chapter_config.id)
      WebMock.stub_request(:patch, "#{@controller.base_path}/#{chapter[:id]}").
        to_return(status: 200, body: chapter.to_json)

      assert_no_difference -> { ChapterConfig.count } do
        assert_no_difference -> { AreaChapterConfig.count } do
          patch :update, params: chapter
          assert_response :ok, response.body
          assert_equal chapter.to_json, response.body
        end
      end

      WebMock.assert_requested(:patch, "#{@controller.base_path}/#{chapter[:id]}")
    end
  end

  should 'handle error response on chapter update' do
    WebMock.stub_request(:patch, "#{@controller.base_path}/#{chapter[:id]}").
      to_return(status: 500, body: 'error')

    assert_no_difference -> { ChapterConfig.count } do
      assert_no_difference -> { AreaChapterConfig.count } do
        patch :update, params: chapter
        assert_response :unprocessable_entity, response.body
        assert response.body.blank?
      end
    end

    WebMock.assert_requested(:patch, "#{@controller.base_path}/#{chapter[:id]}")
  end

  private

  def chapter
    {
      id: 1,
      title: 'dummy chapter',
      content: '<html></html>',
      order: 1
    }
  end

end
