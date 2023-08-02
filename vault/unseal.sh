for i in {0..2}; do
    for s in {1..5}; do
        oc exec -it -n vault vault-$i -- vault operator unseal $(oc get secret vault-token -n vault -o jsonpath={.data.unseal_key_$s} | base64 -d);
    done
done