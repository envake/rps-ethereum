<template>
	<!--<div class="info">Choice: {{ choice }} </div>-->
	<div><p>Make your choice!</p></div>
	
	<div id="choices" class="part">
		<table><tr>
			<td><label>
				<input type="radio" id="rock" value="rock" v-model="choice">
				<img src="../assets/rock.svg"></label>
			</td>
			<td><label>
				<input type="radio" id="paper" value="paper" v-model="choice">
				<img src="../assets/paper-svgrepo-com.svg"></label>
			</td>
			<td><label>
				<input type="radio" id="scissors" value="scissors" v-model="choice">
				<img src="../assets/scissors.svg"></label>
			</td>
		</tr>
		<!--<tr>
			<td>Rock</td>
			<td>Paper</td>
			<td>Scissors</td>
		</tr>--></table>
		<!--<p>{{ choice }}</p>-->
	</div>
	<div class="part">
		<!--<label for="secret">Your Secret: </label>-->
		<input type="text" placeholder="Your password" id="secret" v-model="secret">
		<button v-on:click="commit">Commit (0.01 ether)</button> 
	</div>
</template>

<script>
export default {
	name: "Commit",
	emits: ["commitChoice"],
	data () {
		return {
			choice: "",
			secret: "",
		}
	},
	methods: {
		commit() {
			if (this.choice != "" && this.secret != "") {
				this.$emit("commitChoice", this.choice, this.secret);
			}
			else {
				console.log("Nothing selected.");
			}
		}
	}
};
</script>

<style lang="css" scoped>
#choices input:checked+img {
	border: 2px solid;
	border-color: #E23767;
}
#choices img {
  width: 4em;
  padding: 1em;
  border: 2px solid transparent;
}
#choices img:hover {
	border: 2px solid;
	border-color: #E237673D;
}
#choices [type=radio] {
  -webkit-appearance:none;
  -moz-appearance:none;
  appearance:none;
}
#choices table, label {
	display: inline-block;
}
#choices td {
	padding-left: 2em;
	padding-right: 2em;
}
</style>