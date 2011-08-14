class ListsController < ApplicationController
  # GET /lists
  # GET /lists.json
  def index
    @lists = List.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @lists }
    end
  end

  # GET /lists/1
  # GET /lists/1.json
  def show
    respond_to do |format|
      format.html do
        render :new
      end
      format.json do 
        @list = List.find(params[:id])

        if params[:load]
          return render json: {list: @list, clips: @list.sorted_clips}
        else
          return render json: @list
        end
      end
    end
  end

  # GET /lists/new
  # GET /lists/new.json
  def new
    @list = List.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @list }
    end
  end

  # GET /lists/1/edit
  def edit
    @list = List.find(params[:id])
  end

  # POST /lists
  # POST /lists.json
  def create
    @list = List.new(params[:list])

    respond_to do |format|
      if @list.save
        format.html { redirect_to @list, notice: 'List was successfully created.' }
        format.json { render json: @list, status: :created, location: @list }
      else
        format.html { render action: "new" }
        format.json { render json: @list.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /lists/1
  # PUT /lists/1.json
  def update
    @list = List.find(params[:id])

    respond_to do |format|
      if @list.update_attributes(params[:list])
        format.html { redirect_to @list, notice: 'List was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @list.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /lists/1
  # DELETE /lists/1.json
  def destroy
    @list = List.find(params[:id])
    @list.destroy

    respond_to do |format|
      format.html { redirect_to lists_url }
      format.json { head :ok }
    end
  end

  def save
    @list = List.find(params[:id])
    return render :json => {} if @list.saved

    @list.update_attributes(:name => params[:list][:name], :saved => true)
    return render :json => @list
  end

  def order
    @list = List.find(params[:id])
    @list.update_attributes(:order => params[:list][:order])
    return render :json => @list
  end

  def add_clip
    list = List.find(params[:list_id]) if !params[:list_id].blank?
    list = List.new if !list

    cd = params[:clip]
    clip = Clip.where(:source => cd[:source], :source_id => cd[:source_id]).first
    if !clip
      clip = Clip.new(cd)
      clip.save
    end

    list.clips << clip
    list.save

    render :json => {:list => list, :clip => clip}
  end

  def remove_clip
    list = List.find(params[:id])

    clip = Clip.find(params[:clip_ids])
    if clip
      list.clip_ids.delete clip.id
      list.order.delete clip.id.to_s
      list.save
    end

    render :json => {:list => list}
  end
end
