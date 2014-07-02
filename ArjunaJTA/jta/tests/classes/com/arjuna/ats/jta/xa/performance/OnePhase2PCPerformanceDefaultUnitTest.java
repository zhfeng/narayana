/*
 * JBoss, Home of Professional Open Source
 * Copyright 2006, Red Hat Middleware LLC, and individual contributors 
 * as indicated by the @author tags. 
 * See the copyright.txt in the distribution for a
 * full listing of individual contributors. 
 * This copyrighted material is made available to anyone wishing to use,
 * modify, copy, or redistribute it subject to the terms and conditions
 * of the GNU Lesser General Public License, v. 2.1.
 * This program is distributed in the hope that it will be useful, but WITHOUT A 
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
 * PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.
 * You should have received a copy of the GNU Lesser General Public License,
 * v.2.1 along with this distribution; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, 
 * MA  02110-1301, USA.
 * 
 * (C) 2005-2006,
 * @author JBoss Inc.
 */
/*
 * Copyright (C) 2004,
 *
 * Arjuna Technologies Ltd,
 * Newcastle upon Tyne,
 * Tyne and Wear,
 * UK.  
 *
 * $Id: xidcheck.java 2342 2006-03-30 13:06:17Z  $
 */

package com.arjuna.ats.jta.xa.performance;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;

import java.io.IOException;
import java.util.Calendar;

import org.junit.Test;

import com.arjuna.ats.arjuna.common.arjPropertyManager;
import com.arjuna.ats.internal.arjuna.objectstore.TwoPhaseVolatileStore;
import com.hp.mwtests.ts.jta.common.SampleOnePhaseResource;
import com.hp.mwtests.ts.jta.common.SampleOnePhaseResource.ErrorType;


class Worker7 extends Thread
{

    public Worker7(int iters)
    {
        _iters = iters;
    }

    public void run()
    {
        javax.transaction.TransactionManager tm = com.arjuna.ats.jta.TransactionManager.transactionManager();

        for (int i = 0; i < _iters; i++)
        {
            try 
            {
                tm.begin();

                tm.getTransaction().enlistResource(new SampleOnePhaseResource(ErrorType.none, false));

                tm.commit();
            }
            catch (Exception e) 
            {
                e.printStackTrace();
            }
        }

        OnePhase2PCPerformanceDefaultUnitTest.doSignal();
    }

    private int _iters;

}

public class OnePhase2PCPerformanceDefaultUnitTest
{   
    public static void main (String[] args)
    {
        OnePhase2PCPerformanceDefaultUnitTest obj = new OnePhase2PCPerformanceDefaultUnitTest();

        obj.setWorkSize(1000);

        obj.test();
    }

    public void setWorkSize (int size)
    {
        _sizeOfWork = size;
    }

    @Test
    public void test()
    {
        int threads = 10;
        int work = _sizeOfWork;
        
        arjPropertyManager.getCoordinatorEnvironmentBean().setCommitOnePhase(false);
        
        number = threads;

        int numberOfTransactions = threads * work;
        long stime = Calendar.getInstance().getTime().getTime();
        Worker7[] workers = new Worker7[threads];

        for (int i = 0; i < threads; i++) {
            workers[i] = new Worker7(work);

            workers[i].start();
        }

        OnePhase2PCPerformanceDefaultUnitTest.doWait();

        long ftime = Calendar.getInstance().getTime().getTime();
        long timeTaken = ftime - stime;

        System.out.println("ObjectStore used: "+arjPropertyManager.getObjectStoreEnvironmentBean().getObjectStoreType());
        System.out.println("time for " + numberOfTransactions + " write transactions is " + timeTaken);
        System.out.println("number of transactions: " + numberOfTransactions);
        System.out.println("throughput: " + (float) (numberOfTransactions / (timeTaken / 1000.0)));
    }

    public static void doWait()
    {
        try {
            synchronized (sync) {
                if (number > 0)
                    sync.wait();
            }
        }
        catch (Exception e) {
        }
    }

    public static void doSignal()
    {
        synchronized (sync) {
            if (--number == 0)
                sync.notify();
        }
    }

    int _sizeOfWork = 1000;

    private static Object sync = new Object();
    private static int number = 0;
}