<template>
	<h2>{{ result }}</h2>
	<div>
		<button v-if="canPayout" v-on:click="payout()">Pay me off!</button>
	</div>
</template>

<script>
export default {

	name: 'End',
	emits: ["payoutGame"],
	props: {
		result: String,
		canPayout: Boolean
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