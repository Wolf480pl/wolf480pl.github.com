---
layout: neon-post
title: Testing 123
comments:
  twitter: "#"
---

I was wondering...
How about some Java code?

```java
/*
 * Copyright (c) 2014 Wolf480pl <wolf480@interia.pl>
 * This program is licensed under the GNU Lesser General Public License.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
package com.github.wolf480pl.mias4j.core.runtime;

import java.lang.invoke.CallSite;
import java.lang.invoke.ConstantCallSite;
import java.lang.invoke.MethodHandle;
import java.lang.invoke.MethodHandles;
import java.lang.invoke.MethodType;

import com.github.wolf480pl.mias4j.core.InvocationType;

public class Bootstraps {
    private static RuntimePolicy policy = null;

    public static final String SETPOLICY_NAME = "setPolicy";
    /**
     * Not thread safe! The caller must make sure that this is not called from more than one thread at the same time.
     */
    public static void setPolicy(RuntimePolicy policy) {
        if (policy == null) {
            throw new IllegalArgumentException("policy must not be null");
        }
        if (Bootstraps.policy == null) {
            Bootstraps.policy = policy;
        } else {
            throw new IllegalStateException("tried to set policy twice");
        }
    }

    public static RuntimePolicy getPolicy() {
        return policy;
    }

    private Bootstraps() {
    }

    public static final String WRAPINVOKE_NAME = "wrapInvoke";

    public static CallSite wrapInvoke(MethodHandles.Lookup caller, String invokedName, MethodType invokedType, int opcode, String owner, MethodType originalType) throws NoSuchMethodException,
            IllegalAccessException, ClassNotFoundException {
        InvocationType invType = InvocationType.fromID(opcode);
        if (invType == null) {
            throw new IllegalArgumentException("Invalid InvocationType ID: " + opcode);
        }

        MethodHandle handle = makeHandle(caller, invokedName, invType, owner, originalType).asType(invokedType);
        return new ConstantCallSite(handle);
    }

    public static MethodHandle makeHandle(MethodHandles.Lookup caller, String invokedName, InvocationType invType, String owner, MethodType originalType) throws NoSuchMethodException,
            IllegalAccessException, ClassNotFoundException {

        return policy.intercept(caller, new MethodHandlePrototype(invType, owner, invokedName, originalType));
    }

    public static final String WRAPCONSTRUCTOR_NAME = "wrapConstructor";

    public static CallSite wrapConstructor(MethodHandles.Lookup caller, String invokedName, MethodType invokedType, String owner, MethodType originalType) throws NoSuchMethodException,
            IllegalAccessException, ClassNotFoundException {
        return wrapInvoke(caller, "<init>", invokedType, InvocationType.INVOKENEWSPECIAL.id(), owner, originalType);
    }

    public static final String WRAPSUPERCONSTRUCTORARGS_NAME = "wrapSuperConstructorArguments";

    public static CallSite wrapSuperConstructorArguments(MethodHandles.Lookup caller, String invokedName, MethodType invokedType, String owner, MethodType originalType) {
        InvocationType invType = InvocationType.INVOKESUPERINITSPECIAL;

        MethodHandle defaultHandle;
        try {
            defaultHandle = caller.findConstructor(ArgumentPack.class, MethodType.methodType(Void.TYPE, Object[].class));
        } catch (NoSuchMethodException | IllegalAccessException e) {
            throw new RuntimeException(e); // TODO: sure?
        }
        defaultHandle = defaultHandle.asCollector(Object[].class, originalType.parameterCount());
        defaultHandle = defaultHandle.asType(invokedType);

        MethodInfo method = new ImmutableMethodInfo(invType, owner, invokedName, originalType);

        MethodHandle handle = policy.interceptSuperInitArgs(caller, method, defaultHandle);

        return new ConstantCallSite(handle);
    }

    public static final String WRAPSUPERCONSTRUCTORRES_NAME = "wrapSuperConstructorResult";

    public static CallSite wrapSuperConstructorResult(MethodHandles.Lookup caller, String invokedName, MethodType invokedType, String owner, MethodType originalType) {
        InvocationType invType = InvocationType.INVOKESUPERINITSPECIAL;

        MethodHandle defaultHandle = MethodHandles.constant(Object.class, null);
        Class<?> ownerCls = Object.class; // TODO: will this work?
        defaultHandle = MethodHandles.dropArguments(defaultHandle, 0, ownerCls);
        defaultHandle = defaultHandle.asType(invokedType);

        MethodInfo method = new ImmutableMethodInfo(invType, owner, invokedName, originalType);

        MethodHandle handle = policy.interceptSuperInitResult(caller, method, defaultHandle);

        return new ConstantCallSite(handle);
    }

    public static final String WRAPDYNAMIC_NAME = "wrapInvokeDynamic";

    public static CallSite wrapInvokeDynamic(MethodHandles.Lookup caller, String invokedName, MethodType invokedType, int bsmOpcode, String bsmOwner, String bsmName, MethodType bsmType,
            Object... args) throws Throwable {
        InvocationType invType = InvocationType.fromID(bsmOpcode);
        if (invType == null) {
            throw new IllegalArgumentException("Invalid InvocationType ID: " + bsmOpcode);
        }

        MethodHandle bsm = makeHandle(caller, bsmName, invType, bsmOwner, bsmType);

        Object[] newArgs = new Object[args.length + 3];
        newArgs[0] = caller;
        newArgs[1] = invokedName;
        newArgs[2] = invokedType;
        System.arraycopy(args, 0, newArgs, 3, args.length);
        return (CallSite) bsm.invokeWithArguments(newArgs);
    }

    public static final String WRAPHANDLE_NAME = "wrapHandle";

    public static CallSite wrapHandle(MethodHandles.Lookup caller, String invokedName, MethodType invokedType, int opcode, String owner, MethodType originalType) throws NoSuchMethodException,
            IllegalAccessException, ClassNotFoundException {
        InvocationType invType = InvocationType.fromID(opcode);
        if (invType == null) {
            throw new IllegalArgumentException("Invalid InvocationType ID: " + opcode);
        }

        MethodHandle handle = makeHandle(caller, invokedName, invType, owner, originalType);
        return new ConstantCallSite(MethodHandles.constant(MethodHandle.class, handle));
    }

}
```
