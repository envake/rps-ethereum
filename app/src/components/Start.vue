<template>
	<div>
		<button v-on:click="start">Let's Play!</button>
	</div>
	<div class="text"><p>We've found MetaMask in your Browser! </p></div><div><p>Just connect an Account and you are ready to play.</p></div>
</template>

<script>
export default {
  name: 'Start',
  emits: ["start"],
  data () {
		return {
		}
	},
	methods: {
		start() {
			this.$emit("start");
		},
	}
};
</script>

<style lang="css" scoped>
.text {
	margin-top:  6em;
}
</style>