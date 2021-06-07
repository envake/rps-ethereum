<template>
	<div>
		<button v-on:click="reveal()">Reveal</button>
	</div>
</template>

<script>
export default {

  name: "Reveal",
  emits: ["revealChoice"],
  data () {
    return {

    }
  },
  methods: {
    reveal() {
      this.$emit("revealChoice");
    }
  }
};
</script>

<style lang="css" scoped>
</style>