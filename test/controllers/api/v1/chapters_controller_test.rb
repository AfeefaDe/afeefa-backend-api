require 'test_helper'

class Api::V1::ChaptersControllerTest < ActionController::TestCase
  setup do
    @user = valid_user
    stub_current_user(user: @user)
  end

  test 'get show without login' do
    WebMock.stub_request(:get, "#{@controller.base_path}/1").to_return(body: chapter.to_json)
    unstub_current_user

    get :show, params: { id: 1 }
    assert_response :ok, response.body
    assert_equal chapter.to_json, response.body

    WebMock.assert_requested(:get, "#{@controller.base_path}/1")
  end

  test 'get empty list of chapters' do
    WebMock.stub_request(:get, "#{@controller.base_path}").to_return(body: '[]')

    get :index
    assert_response :ok, response.body
    json = JSON.parse(response.body)
    assert_equal [], json
  end

  test 'get empty list of chapters without wisdom api request for missing config' do
    AreaChapterConfig.delete_all

    get :index
    assert_response :ok, response.body
    json = JSON.parse(response.body)
    assert_equal [], json
  end

  test 'get area filtered list of chapters' do
    api_reponse = '[{"id":1,"title":"new chapter","content":"<p>test</p>","order":1,"createdAt":"2018-01-10T10:17:04.000Z","updatedAt":"2018-01-10T16:17:42.000Z"}]'
    WebMock.stub_request(:get, "#{@controller.base_path}?ids=1,2,3").to_return(body: api_reponse)

    create_dummy_chapter_configuration

    get :index
    assert_response :ok, response.body
    assert_equal api_reponse, response.body

    WebMock.assert_requested(:get, "#{@controller.base_path}?ids=1,2,3")
  end

  test 'create chapter' do
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

  test 'handle error response on chapter create' do
    WebMock.stub_request(:post, "#{@controller.base_path}").to_return(status: 500, body: 'error')

    assert_no_difference -> { ChapterConfig.count } do
      assert_no_difference -> { AreaChapterConfig.count } do
        post :create, params: chapter.except(:id)
        assert_response :unprocessable_entity
        assert response.body.blank?
      end
    end

    WebMock.assert_requested(:post, "#{@controller.base_path}")
  end

  test 'update chapter' do
    chapter_config = ChapterConfig.create!(chapter_id: chapter[:id])
    area_chapter_config = AreaChapterConfig.create!(area: @user.area, chapter_config_id: chapter_config.id)
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

  test 'handle error response on chapter update' do
    WebMock.stub_request(:patch, "#{@controller.base_path}/#{chapter[:id]}").
      to_return(status: 500, body: 'error')

    assert_no_difference -> { ChapterConfig.count } do
      assert_no_difference -> { AreaChapterConfig.count } do
        patch :update, params: chapter
        assert_response :unprocessable_entity
        assert response.body.blank?
      end
    end

    WebMock.assert_requested(:patch, "#{@controller.base_path}/#{chapter[:id]}")
  end

  test 'destroy chapter' do
    WebMock.stub_request(:delete, "#{@controller.base_path}/#{chapter[:id]}").to_return(status: 204, body: '')

    chapter_config = ChapterConfig.create!(chapter_id: chapter[:id], active: true)
    area_chapter_config = AreaChapterConfig.create!(area: @user.area, chapter_config_id: chapter_config.id)

    assert_difference -> { ChapterConfig.count }, -1 do
      assert_difference -> { AreaChapterConfig.count }, -1 do
        delete :destroy, params: chapter.slice(:id)
        assert_response 204, response.body
        assert response.body.blank?
      end
    end

    WebMock.assert_requested(:delete, "#{@controller.base_path}/#{chapter[:id]}")
  end

  test 'handle error response on chapter destroy' do
    WebMock.stub_request(:delete, "#{@controller.base_path}/#{chapter[:id]}").
      to_return(status: 500, body: 'error')

    chapter_config = ChapterConfig.create!(chapter_id: chapter[:id], active: true)
    area_chapter_config = AreaChapterConfig.create!(area: @user.area, chapter_config_id: chapter_config.id)

    assert_no_difference -> { ChapterConfig.count } do
      assert_no_difference -> { AreaChapterConfig.count } do
        delete :destroy, params: chapter.slice(:id)
        assert_response :unprocessable_entity
        assert response.body.blank?
      end
    end

    WebMock.assert_requested(:delete, "#{@controller.base_path}/#{chapter[:id]}")
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

  def create_dummy_chapter_configuration
    c1 = ChapterConfig.create!(chapter_id: 1, active: true)
    c2 = ChapterConfig.create!(chapter_id: 2, active: true)
    c3 = ChapterConfig.create!(chapter_id: 3, active: true)
    AreaChapterConfig.create!(chapter_config_id: c1.id, area: @user.area)
    AreaChapterConfig.create!(chapter_config_id: c2.id, area: @user.area)
    AreaChapterConfig.create!(chapter_config_id: c3.id, area: @user.area)
  end
end
