class ArticlesController < ApplicationController
  def index
    @article = Article.new
    
    @articles = if params[:tag]
      Article.tagged_with(params[:tag])
    else
      Article.all
    end
  end

  def new
  end
  
  def create
    @article = Article.new(article_params)
    respond_to do |format|
      if @article.save
        format.js
      else
        format.html { render root_path }
      end
    end
  end
  
  private
  
  def article_params
    params.require(:article).permit(:author, :content, :all_tags)
  end
end
