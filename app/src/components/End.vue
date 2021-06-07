<template>
	<h2>{{ result }}</h2>
	<div>
		<button v-on:click="payout()">Pay me off!</button>
	</div>
</template>

<script>
export default {

	name: 'End',
	emits: ["payoutGame"],
	props: {
		result: String
	},
	data () {
		return {

		}
	},
	methods: {
    payout() {
      this.$emit("payoutGame");
    }
  }
};
</script>

<style lang="css" scoped>
</style>