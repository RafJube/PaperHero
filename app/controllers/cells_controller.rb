class CellsController < ApplicationController
  def play
    # On trouve la cell et on la met à jour
    cell = Cell.find(params[:id])
    cell.hit = true if cell.full
    cell.state = "waiting"
    cell.save
    paper_ball_throw = false

    # On trouve le game et les deux grilles et on met à jour
    @game = cell.grid.game
    user_grid = Grid.find_by(game: cell.grid.game, playing: true)
    opponent_grid = Grid.find(cell.grid_id)
    opponent_grid.hit_count += 1 if cell.full
    opponent_grid.shot_count += 1
    if (opponent_grid.shot_count % 4 != 0)
      opponent_grid.save
    else
      paper_ball_throw = true
      opponent_grid.shot_count = 0
      waiting_cells = []
      opponent_grid.cells.where(state: "waiting").each do |cell|
        cell.state = "visible"
        cell.visible = true
        cell.save
        waiting_cells << cell.id
      end
      opponent_grid.update(playing: true)
      user_grid.update(playing: false)
    end

    update_desk(cell)

    # Si la game est finie
    if opponent_grid.hit_count >= @game.cells_number
      opponent_grid.update(playing: false)
      user_grid.update(playing: false)
      opponent_grid.game.update(ongoing: false)
      user_grid.update(win: true)
      opponent_grid.update(playing: false)
      user_grid.update(playing: false)
      user_grid.game.update(ongoing: false)
    end

    game_ongoing = user_grid.game.ongoing
    next_player = user_grid.playing ? user_grid.user : opponent_grid.user

    # Pour régler le problème des cellules qui partent en couille.
    cells_opponent = opponent_grid.ordered_cells
    cells_current_user = user_grid.ordered_cells
    # Action Cable
    GameChannel.broadcast_to(
      @game,
      {
        current_user_id: current_user.id,
        left_grid: render_to_string(partial: "partials/grid", locals: { left_grid: opponent_grid, right_grid: user_grid, visible: true, grid_cells: cells_opponent, paper_ball_throw: paper_ball_throw }),
        right_grid: render_to_string(partial: "partials/grid", locals: { left_grid: user_grid, right_grid: opponent_grid, visible: false, grid_cells: cells_current_user }),
        # waiting_phrase: render_to_string(partial: "partials/phrases", locals: { left_grid: opponent_grid, right_grid: user_grid }),
        # playing_phrase: render_to_string(partial: "partials/phrases", locals: { left_grid: user_grid, right_grid: opponent_grid }),
        current_user_left_grid: render_to_string(partial: "partials/grid", locals: { left_grid: user_grid, right_grid: opponent_grid, visible: true, grid_cells: cells_current_user }),
        current_user_right_grid: render_to_string(partial: "partials/grid", locals: { left_grid: opponent_grid, right_grid: user_grid, visible: false, grid_cells: cells_opponent, paper_ball_throw: paper_ball_throw }),
        ongoing: game_ongoing,
        paper_ball_throw: paper_ball_throw,
        grid_target: opponent_grid.id,
        waiting_cells: waiting_cells,
        next_player: "It's #{next_player.username}'s turn!",
        trophy_image: render_to_string(partial: "shared/trophy"),
        defeat_image: render_to_string(partial: "shared/defeat")
      }
    )
    respond_to do |format|
      format.html { redirect_to game_path(cell.grid.game.id) }
      format.js
    end
  end

  def update_desk(cell)
    opponent_grid = Grid.find(cell.grid_id)
    desks = Desk.where(grid: opponent_grid)
    cell_coordinate = coord(cell.position)
    desks.each do |desk|
      area = area(coord(desk.pos_origin), [desk.size_x, desk.size_y])
      desk.hit_count += 1 if (area & [cell_coordinate]).size.positive?
      desk.hit = true if desk.hit_count == (desk.size_x * desk.size_y)
      desk.save
    end
  end
end
