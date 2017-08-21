require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"

#this sets up sinatra to use sessions
configure do 
  enable :sessions
  set :session_secret, 'secret'
end

helpers do 
  def list_complete?(list)
    todos_count(list) > 0 && todos_remaining_count(list) == 0
  end

  def list_class(list)
    "complete" if list_complete?(list)
  end

  def todos_remaining_count(list)
    list[:todos].select { |todo| !todo[:completed] }.size
  end

  def todos_count(list)
    list[:todos].size
  end

  def sort_lists(lists, &block)
    complete_lists, incomplete_lists = lists.partition { |list| list_complete?(list)}

    incomplete_lists.each { |list| yield list, lists.index(list) }
    complete_lists.each { |list| yield list, lists.index(list) }
  end

  def sort_todos(todos, &block)
    complete_todos, incomplete_todos = todos.partition { |todo| todo[:completed] }

    incomplete_todos.each { |todo| yield todo, todos.index(todo) }
    complete_todos.each { |todo| yield todo, todos.index(todo) }
  end

end

before do 
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

#view list of lists
get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

#render new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

#creating new lists
post "/lists" do
  list_name = params[:list_name].strip 

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << {name: list_name, todos: []}
    session[:success] = "This list has been created."
    redirect "/lists"
  end
end

get "/lists/:id" do
  id = params[:id].to_i
  @list_id = id
  @list = session[:lists][@list_id]
  erb :list, layout: :layout
end

#edit existing to do list
get "/lists/:id/edit" do
  @list = session[:lists][params[:id].to_i]
  erb :edit_list, layout: :layout
end

#delete a todo list
post "/lists/:id/destroy" do 
  id = params[:id].to_i
  session[:lists].delete_at(id)
  session[:success] = "The list has been deleted"
  redirect "/lists"
end

#add a new todo to a list
post "/lists/:list_id/todos" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  text = params[:todo].strip

  error = error_for_todo(text)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @list[:todos] << {name: text, completed: false}
    session[:success] = "The todo was added."
    redirect "/lists/#{@list_id}"
  end
end

#update existing todo list
post "/lists/:id" do
  list_name = params[:list_name].strip 
  id = params[:id].to_i
  @list = session[:lists][id]

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    @list[:name] = list_name
    session[:success] = "This list has been updated."
    redirect "/lists/#{id}"
  end
end

#destroy a todo from a list
post "/lists/:list_id/todos/:id/destroy" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]

  todo_id = params[:id].to_i
  @list[:todos].delete_at todo_id
  session[:success] = "The todo has been deleted."
  redirect "/lists/#{@list_id}"
end

#update the status of the todo
post "/lists/:list_id/todos/:id" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]

  todo_id = params[:id].to_i
  is_completed = params[:completed] == "true"
  @list[:todos][todo_id][:completed] = is_completed
  session[:success] = "The todo has been updated."
  redirect "/lists/#{@list_id}"
end


#mark all todos complete
post "/lists/:id/complete_all" do 
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]

  @list[:todos].each do |todo|
    todo[:completed] = true
  end 

  session[:success] = "All the todos have been checked off."
  redirect "/lists/#{@list_id}"
end





#return an error message if the name is invalid. return nil is name is valid.
def error_for_list_name(name)
  if !(1..100).cover? name.size
    "The list name must be between one and a hundred characters."
  elsif session[:lists].any? {|list| list[:name] == name}
    "List name must be unique."
  end
end

def error_for_todo(name)
  if !(1..100).cover? name.size
    "Todo must be between one and a hundred characters."
  end
end
















