import { Controller } from "@hotwired/stimulus"
import consumer from "../channels/consumer"
import { Modal } from 'bootstrap'

export default class extends Controller {
  static targets = ["currentUser", "opponent", "button", "leftphrase", "rightphrase", "grid"]
  static values = { gameId: Number, currentUserId: Number }

  connect() {
    this.channel = consumer.subscriptions.create(
      { channel: "GameChannel", id: this.gameIdValue },
    //   { received: data => console.log(data) }
    //   { received: data => this.userTarget.innerHTML = data.left_grid }
      { received: data => {
        if (!data.ongoing) {
          this.myModal = new Modal(document.getElementById('victory_modal'), {
            keyboard: false
          })
          this.myModal.show();
          const title = document.getElementById("staticBackdropLabel")
          if (this.currentUserIdValue === data.current_user_id) {
            title.innerHTML = "<img class='result-game' src='/assets/trophy_new.png'> Victory! <img class='result-game' src='/assets/trophy_new.png'>";
          } else {
            title.innerHTML = "<img class='result-game' src='/assets/disappointed-face.png'> Game over... <img class='result-game' src='/assets/disappointed-face.png'>";

          }
        } else {
          if (data.paper_ball_throw) {
            if (this.currentUserIdValue === data.current_user_id){
              this.throwFromLeft(data)
              setTimeout(() => {
                this.currentUserTarget.innerHTML = data.current_user_left_grid;
                this.opponentTarget.innerHTML = data.current_user_right_grid;
                this.leftphraseTarget.innerHTML = data.user_phrase;
              }, 2000);
            } else {
              this.throwFromRight(data)
              setTimeout(() => {
                this.currentUserTarget.innerHTML = data.left_grid;
                this.opponentTarget.innerHTML = data.right_grid;
                this.buttonTarget.innerHTML = data.button;
                this.leftphraseTarget.innerHTML = data.opponent_phrase;
              }, 2000);
            }
          } else if (this.currentUserIdValue === data.current_user_id){
            this.currentUserTarget.innerHTML = data.current_user_left_grid;
            this.opponentTarget.innerHTML = data.current_user_right_grid;
          }
        }
      }}
    )
  }

  throwFromLeft(data) {
    data.waiting_cells.forEach(id => {
      console.log(id);
      const waitingTds = document.querySelector(`#cell-${id}`)
      console.log(waitingTds);
      waitingTds.classList.add('anim-left')
    })
  }

  throwFromRight(data) {
    data.waiting_cells.forEach(id => {
      console.log(id);
      const waitingTds = document.querySelector(`#cell-${id}`)
      console.log(waitingTds);
      waitingTds.classList.add('anim-right')
    })
  }
}
