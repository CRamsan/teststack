#!/bin/bash

source functions.sh

###################################################################################

func_replace_param "./replace_function/sample.txt" "Hello" "Hi"
func_replace_param "./replace_function/sample.txt" "This" "this"
func_replace_param "./replace_function/sample.txt" "Is" "is"
func_replace_param "./replace_function/sample.txt" "Hi" "Hello"

